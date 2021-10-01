/**
 *Submitted for verification at BscScan.com on 2021-10-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
  
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

   
    function isApprovedForAll(address owner, address operator) external view returns (bool);

  
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "add: +");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "sub: -");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
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
        require(c / a == b, "mul: *");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "div: /");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "mod: %");
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
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) internal virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}



pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface I_NFT_Registry {

    /**
    * @dev Structs
    */
    
    //
    // Contain registered state and settings for each ERC20 token.
    //
    struct ERC20Token {
        address contract_address;
        string symbol;
        bool active;
        string meta;
    }
    
    //
    // Contain registered state and settings for each ERC721 token.
    //
    struct ERC721Token {
        address contract_address;
        string name;
        uint256 max_supply;
        uint256[] max_supply_history;
        address owner;
        address payee;
        bool active;
        string meta;
    }
    
    //
    // Contain mapping for slot
    //
    struct NFTSlots {
        mapping(uint256 => SlotState) slots;
    }

    //
    // Struct for each single slot of a NFT (ERC721 Token)
    //  which contains of 
    //  - serial no. to identify the slot (Work as token ID),
    //  - flexible status of the slot, it normally use
    //      1. [blank] for being unused.
    //      2. "RSV" for being reserved.
    //      3. "CLM_[wallet_address]" for 
    //  - its existence (as indicator of usage)
    //  - create timestamp.
    //  - update timestamp.
    //  - a remark note.
    //  - and meta information (Dynamic string for JSON or compressed format.)
    //
    struct SlotState {
        bool exists;
        uint256 serial_no;
        string status;
        uint256 timestamp;
        string remark; 
        string meta;
        address operator;
    }

    function getERC721token(address erc721_address) external returns (ERC721Token memory);

    function getNFTslotState(address erc721_address, uint256 serial_no) external returns (SlotState memory);
    
    function setNFTslotState(address erc721_address, uint256 serial_no, string memory status, string memory remark, string memory meta) external returns (SlotState memory);
    
    function updateNFTslotState(address erc721_address, uint256 serial_no, string memory status, string memory remark, string memory meta) external payable returns (SlotState memory);
    
    function getExchangeRateForNFTcollection(address erc721_address, address erc20_address) external returns (uint256);
    
    function getExchangeRateForSpecificNFT(address erc721_address, uint256 serial_no, address erc20_address) external returns (uint256);
    
    function getMinimumExchangeRate(address erc20_address) external returns (uint256);
    
    function changeExchangeRateForSingleNFT(address erc721_address, uint256 serial_no, address erc20_address, uint256 rate) external;

}


pragma solidity ^0.8.0;





contract NFT_Registry is Ownable, I_NFT_Registry {
    using SafeMath for uint256;


    /**
    * @dev Data Structures and Global Variables
    */

    //
    // Contract owner address.
    //
    address private $owner;

    //
    // Wallet address to receive transfer in of all ERC20.
    //
    address private $payee;
    

    //
    // Map for store registry of accept ERC20 tokens which contain setting and its meta data.
    //
    mapping(address => ERC20Token) private $ERC20Tokens;

    //
    // Map for store registry of NFTs (ERC721 tokens) which contain setting and its meta data.
    //
    mapping(address => ERC721Token) private $ERC721Tokens;

    //
    // Map for store exchange rate of an ERC20 token for each ERC721 collection. 
    //
    mapping(address => mapping(address => uint256)) private $exchangeRateDefault;

    //
    // Map for store exchange rate of an ERC20 token for each ERC721 token. 
    //
    mapping(address => mapping(uint256 => mapping(address => uint256))) private $exchangeRateNFT;
    
    //
    // Map for store minimum exchange rate of each ERC20 token.
    //
    mapping(address => uint256) private $minExchangeRate;

    //
    // Map for store slot of reserved, used, claimed slot of ERC721 tokens
    //  it's a double map which use contract address of a NFT to access the store
    //  and use serial number (uint256) to access the token slot.
    // 
    mapping(address => NFTSlots) $NFTslots;

    //
    // Map for store permitted operator (e.g. another contract that call this contract).
    // 
    mapping(address => bool) private $permitted_operator;
    

    /**
    * @dev Event Emitters
    */

    //
    // Event for NFT slot update
    //
    event SlotUpdate(
        address indexed erc721_address,
        uint256 serial_no,
        string status,
        uint256 timestamp
    );



    /**
    * @dev Constructor
    */

    // Simply setup contract owner and payee to deployer address
    constructor() {
        $owner = msg.sender;
        $permitted_operator[msg.sender] = true;
    }


    /**
    * @dev Public Functionalities
    */


    /**
    * @dev Contract Setup and Administrations
    */
    
    //
    // Change Contract Owner Address
    //
    function changeOwner(
        address new_address
    ) public onlyOwner {
        require(new_address != $owner && new_address != address(0), "E:[PM02]");
        $owner = new_address;
        transferOwnership($owner);
    }

    //
    // Change Contract Owner Address
    //
    function activateOperator(
        address operator_address
    ) public onlyOwner {
        if ($permitted_operator[operator_address]) {
            $permitted_operator[operator_address] = !$permitted_operator[operator_address];
        } else {
            $permitted_operator[operator_address] = true;
        }
    }

    /**
    * @dev NFT (ERC721 Tokens) Functionalities
    */

    //
    // Change Owner Address for a registered ERC721.
    //
    function changeERC721Owner(
        address erc721_address,
        address new_address
    ) public {
        require(
          ($ERC721Tokens[erc721_address].owner != new_address && new_address != address(0))
          || msg.sender == $owner
        , "E:[PM02]");
        $ERC721Tokens[erc721_address].owner = new_address;
    }

    //
    // Change Payee Address for a registered ERC721.
    //
    function changeERC721Payee(
        address erc721_address,
        address new_address
    ) public {
        require($ERC721Tokens[erc721_address].owner == msg.sender, "E:[PM01]");
        require($ERC721Tokens[erc721_address].payee != new_address && new_address != address(0), "E:[PM03]");
        $ERC721Tokens[erc721_address].payee = new_address;
    }

    //
    // Get details of a registered ERC721 token.
    //
    function getERC721token(
        address erc721_address
    )
        override
        public
        view
        returns (ERC721Token memory)
    {
        return $ERC721Tokens[erc721_address];
    }

    //
    // Register an ERC721 token to be usable with this contract.
    //
    function registerERC721token(
        address erc721_address,
        string memory name,
        uint256 max_supply,
        address erc20_address,
        address erc721_owner_address,
        address erc721_payee_address,
        uint256 exchange_rate
    )
        public
        onlyOwner
    {
        $ERC721Tokens[erc721_address].contract_address = erc721_address;
        $ERC721Tokens[erc721_address].name = name;
        $ERC721Tokens[erc721_address].max_supply = max_supply;
        $ERC721Tokens[erc721_address].owner = erc721_owner_address;
        
        if (erc721_payee_address != address(0)) {
            $ERC721Tokens[erc721_address].payee = erc721_payee_address;
        } else {
            $ERC721Tokens[erc721_address].payee = erc721_owner_address;
        }
        $ERC721Tokens[erc721_address].active = true;
        if (exchange_rate > 0) {
            $exchangeRateDefault[erc721_address][erc20_address] = exchange_rate;
        } else {
            $exchangeRateDefault[erc721_address][erc20_address] = $minExchangeRate[erc20_address];
        }
    }

    //
    // Switch current state of a registered ERC721 token (Activate <> Deactive).
    //
    function activateERC721token(
        address erc721_address
    )
        public
    {
        //
        require($ERC721Tokens[erc721_address].owner == msg.sender, "E:[PM01]");
        $ERC721Tokens[erc721_address].active = !$ERC721Tokens[erc721_address].active;
    }

    //
    // Set max supply for ERC721 (Can be changed only once).
    //
    function setNFTmaxSupply(
        address erc721_address,
        uint256 max_supply
    )
        public
    {
        //
        require($ERC721Tokens[erc721_address].owner == msg.sender, "E:[PM01]");
        require($ERC721Tokens[erc721_address].max_supply == 0, "E:[TK11]");
        $ERC721Tokens[erc721_address].max_supply = max_supply;
    }

    //
    // Set max supply for ERC721 (can be changed only once).
    //
    function overrideNFTmaxSupply(
        address erc721_address,
        uint256 max_supply
    )
        public
    {
        require($ERC721Tokens[erc721_address].owner == msg.sender, "E:[PM01]");
        $ERC721Tokens[erc721_address].max_supply_history.push($ERC721Tokens[erc721_address].max_supply);
        $ERC721Tokens[erc721_address].max_supply = max_supply;
    }

    //
    // Bulk setup reservation states for each NFT. 
    //
    function setNFTreserveList(
        address erc721_address,
        uint256[] memory reserve_list
    )
        public
    {
        require($ERC721Tokens[erc721_address].max_supply > 0, "E:[TK12]");
        require($ERC721Tokens[erc721_address].owner == msg.sender, "E:[PM01]");
        
        for (uint8 i = 0; i < reserve_list.length; i++) {
            uint256 _serial_no = reserve_list[i];
            SlotState memory _slot = $NFTslots[erc721_address].slots[_serial_no];
            if (!_slot.exists && _serial_no <= $ERC721Tokens[erc721_address].max_supply) {
                _slot.status = "RSV";
                _slot.exists = true;
                _slot.serial_no = _serial_no;

                $NFTslots[erc721_address].slots[_serial_no] = _slot;
            }
        }
    }

    //
    // Bulk remove reserved NFT slot.
    //
    function removeNFTreserveList(
        address erc721_address,
        uint256[] memory reserve_list
    )
      public
    {
        require($ERC721Tokens[erc721_address].owner == msg.sender, "E:[PM01]");

        for (uint8 i = 0; i < reserve_list.length; i++) {
            uint256 _serial_no = reserve_list[i];
            SlotState memory _slot = $NFTslots[erc721_address].slots[_serial_no];
            if (_compareStrings(_slot.status , "RSV")) {
                $NFTslots[erc721_address].slots[_serial_no].status = "";
            }
        }
    }

    // 
    // Get detail of an NFT slot
    //
    function getNFTslotState(
        address erc721_address,
        uint256 serial_no
    )
        override
        public
        view
        returns (SlotState memory)
    {
        SlotState memory _slot = $NFTslots[erc721_address].slots[serial_no];
        
        return _slot;
    }

    // 
    // Set details for an NFT slot - Can be set only once.
    //
    function setNFTslotState(
        address erc721_address,
        uint256 serial_no,
        string memory status,
        string memory remark,
        string memory meta
    )
        override
        public
        returns (SlotState memory)
    {
        
        require($permitted_operator[msg.sender], "E:[PM04]");
        require($ERC721Tokens[erc721_address].active, "E:[TK10]");

        SlotState memory _slot = $NFTslots[erc721_address].slots[serial_no];
        require(!_slot.exists, "E:[RE01]");

        SlotState memory slot_ = SlotState(
          true,             // bool exists;
          serial_no,        // uint256 serial_no;
          status,           // string status;
          block.timestamp,  // uint256 timestamp;
          remark,           // string remark; 
          meta,             // string meta;
          msg.sender        // address operator;
        );

        $NFTslots[erc721_address].slots[serial_no] = slot_;
    
        emit SlotUpdate(erc721_address, serial_no, status, block.timestamp);

        return slot_;
    }

    //
    // Update details for an NFT slot by
    //
    function updateNFTslotState(
        address erc721_address,
        uint256 serial_no,
        string memory status,
        string memory remark,
        string memory meta
    )
        override
        payable
        public
        returns (SlotState memory)
    {
        require($permitted_operator[msg.sender], "E:[PM04]");
        require($ERC721Tokens[erc721_address].active, "E:[TK10]");

        require($NFTslots[erc721_address].slots[serial_no].exists, "E:[RE01]");
        $NFTslots[erc721_address].slots[serial_no].status = status;
        $NFTslots[erc721_address].slots[serial_no].remark = remark;
        $NFTslots[erc721_address].slots[serial_no].meta = meta;
        $NFTslots[erc721_address].slots[serial_no].timestamp = block.timestamp;

        emit SlotUpdate(erc721_address, serial_no, status, block.timestamp);

        return $NFTslots[erc721_address].slots[serial_no];
    }

    /**
    * @dev ERC20 Tokens (Quote Token) Functionalities
    */

    //
    // Get details of a registered ERC20 token.
    //
    function getERC20token(
        address erc20_address
    )
        public
        view 
        returns (ERC20Token memory)
    {
        return $ERC20Tokens[erc20_address];
    }

    //
    // Register an ERC20 token to be usable with this contract.
    //
    function registerERC20token(
        address erc20_address,
        string memory symbol
    )
        public
    {
        require($permitted_operator[msg.sender], "E:[PM04]");
        $ERC20Tokens[erc20_address].contract_address = erc20_address;
        $ERC20Tokens[erc20_address].symbol = symbol;
        $ERC20Tokens[erc20_address].active = true;
    }

    //
    // Remove an ERC20 token from the registry.
    //
    function removeERC20token(
        address erc20_address
    )
        public
    {
        require($permitted_operator[msg.sender], "E:[PM04]");
        delete $ERC721Tokens[erc20_address];
    }

    //
    // Change exchange rate for an ERC20 with an ERC721 NFT.
    //
    function changeExchangeRate(
        address erc721_address,
        address erc20_address,
        uint256 exchange_rate
    )
        public
    {
        require($ERC721Tokens[erc721_address].active, "E:[TK10]");
        require($ERC20Tokens[erc20_address].active, "E:[TK20]");
        require($ERC721Tokens[erc721_address].owner == msg.sender, "E:[PM01]");
        $exchangeRateDefault[erc721_address][erc20_address] = exchange_rate;
    }
    
    //
    // Set exchange rate for a specific ERC20 token for a specific ERC721 NFT.
    //
    function changeExchangeRateForSingleNFT(
        address erc721_address,
        uint256 serial_no,
        address erc20_address,
        uint256 exchange_rate
    )
        override
        public
    {
        require($ERC721Tokens[erc721_address].active, "E:[TK10]");
        require($ERC20Tokens[erc20_address].active, "E:[TK20]");
        require($permitted_operator[msg.sender], "E:[PM04]");
        $exchangeRateNFT[erc721_address][serial_no][erc20_address] = exchange_rate;
    }
    
    //
    // Get exchange rate for a specific ERC20 token bind with a specific ERC721 collection.
    //
    function getExchangeRateForNFTcollection(
        address erc721_address,
        address erc20_address
    )
        override
        public
        view
        returns (uint256)
    {
        return $exchangeRateDefault[erc721_address][erc20_address];
    }

    //
    // Get exchange rate for a specific ERC20 token bind with a specific ERC721 token.
    //
    function getExchangeRateForSpecificNFT(
        address erc721_address,
        uint256 serial_no,
        address erc20_address
    )
        override
        public
        view
        returns (uint256)
    {
        return $exchangeRateNFT[erc721_address][serial_no][erc20_address];
    }

    //
    // Get exchange rate for a specific ERC20 token bind with a specific ERC721 token.
    //
    function getMinimumExchangeRate(
        address erc20_address
    )
        override
        public
        view
        returns (uint256)
    {
        return $minExchangeRate[erc20_address];
    }


    /**
    * @dev Internal Utilities
    */

    //
    // Simply compare two strings.
    //
    function _compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }


    /**
    * @dev Error Codes
    *
    * E:[0000] Undefined error.
    *
    *** Permissions
    *
    * E:[PM01] Caller must be the owner of the registered ERC721 token.
    *
    * E:[PM02] New owner address must not be the same as the current one.
    *
    * E:[PM03] New payee address must not be the same as the current one.
    *
    * E:[PM04] Caller must be a permitted operator.
    *
    *** Tokens
    *
    * E:[TK10] ERC721 token was not active or registered.
    *
    * E:[TK11] To set max supply of an NFT, it needed to be zero.
    *
    * E:[TK12] NFT max supply was not set.
    *
    * E:[TK20] ERC20 token was not active or registered.
    *
    *** Registry and Entries
    *
    * E:[RE01] NFT slot must be set before.
    *
    ***
    */
}




pragma solidity ^0.8.0;




contract NFT_Swap__V0_1 is Ownable {
    using SafeMath for uint256;

    NFT_Registry NFTregistry;


    /**
    * @dev Structs
    */

    /**
    * @dev Data Structures and Global Variables
    */

    //
    // Contract owner address.
    //
    address private $owner;

    //
    // Wallet address to receive transfer in of all ERC20.
    //
    address private $payee;
    //
    //  NFT Registry address to work with.
    //
    address private $native;
    
    
    address public $nft_registry;


    /**
    * @dev Event Emitters
    */

    //
    // Event for NFT Swap transaction
    //
    event NFTswap(
        address indexed buyer,
        address indexed erc721_address,
        uint256 serial_no,
        address indexed erc20_address,
        uint256 amount,
        uint256 timestamp
    );


    /**
    * @dev Constructor
    */

    // Simply setup contract owner and payee to deployer address
    constructor(
        address nft_registry,
        address warpBNBaddress
    ) {
        $owner = msg.sender;
        $payee = msg.sender;
        $native = warpBNBaddress;
        $nft_registry = nft_registry;
        NFTregistry = NFT_Registry(nft_registry);
    }

    /**
    * @dev Public Functionalities
    */

    //
    // Swap registered ERC20 token with an available ERC721 token slot 
    //  and mark status for the slot.
    //
    function swapNFT(
        address erc721_address,
        uint256 serial_no,
        address erc20_address,
        uint256 amount,
        string memory remark,
        string memory meta
    )
        public
    {
      I_NFT_Registry.ERC721Token memory _ERC721_Token = NFTregistry.getERC721token(erc721_address);
      I_NFT_Registry.SlotState memory _slot = NFTregistry.getNFTslotState(erc721_address, serial_no);
      uint256 _exchange_rate_default = NFTregistry.getExchangeRateForNFTcollection(erc721_address, erc20_address);
      uint256 _exchange_rate_specific = NFTregistry.getExchangeRateForSpecificNFT(erc721_address, serial_no, erc20_address);
      
      uint256 _exchange_rate = _exchange_rate_default;
      if (_exchange_rate_specific > 0) {
          _exchange_rate = _exchange_rate_specific;
      }

      // Checking for supported ERC20 tokens.
      require(_ERC721_Token.active, "E:[X001]");

      // Checking for ERC20 amount and it must be matched with the specified exchange rate.
      require(_exchange_rate <= amount, "E:[EX01]");
      
      // Checking for available NFT Slot in an ERC721 token
      require(!_slot.exists, "E:[EX02]");

      // Transfer ERC20 token to the payee address
      require(IERC20(erc20_address).transferFrom(msg.sender, $payee, amount), "E:[TK21]");

      // Transfer ERC721 token to message sender address.
      IERC721(erc721_address).safeTransferFrom(_ERC721_Token.owner, msg.sender, serial_no, "");

      // Set status for the token slot
      NFTregistry.setNFTslotState(
        erc721_address, // ERC721 address
        serial_no, // Serial No.
        "CLAIMED", // Status
        remark, // Remarks
        meta // Meta
      );

      emit NFTswap(msg.sender, erc721_address, serial_no, erc20_address, amount, block.timestamp);
    }
    
    function swapNFTbyNative(
        address erc721_address,
        uint256 serial_no,
        //address erc20_address,
        //uint256 amount,
        string memory remark,
        string memory meta
    )
        public payable
    {
      I_NFT_Registry.ERC721Token memory _ERC721_Token = NFTregistry.getERC721token(erc721_address);
      I_NFT_Registry.SlotState memory _slot = NFTregistry.getNFTslotState(erc721_address, serial_no);
      uint256 _exchange_rate_default = NFTregistry.getExchangeRateForNFTcollection(erc721_address, $native);
      uint256 _exchange_rate_specific = NFTregistry.getExchangeRateForSpecificNFT(erc721_address, serial_no, $native);
      
      uint256 _exchange_rate = _exchange_rate_default;
      if (_exchange_rate_specific > 0) {
          _exchange_rate = _exchange_rate_specific;
      }

      // Checking for supported ERC20 tokens.
      require(_ERC721_Token.active, "E:[X001]");

      // Checking for ERC20 amount and it must be matched with the specified exchange rate.
      require(_exchange_rate <= msg.value, "E:[EX01]");
      
      // Checking for available NFT Slot in an ERC721 token
      require(!_slot.exists, "E:[EX02]");

      // Transfer ERC20 token to the payee address
      safeTransferBNB($payee, msg.value);
    
      // Transfer ERC721 token to message sender address.
      IERC721(erc721_address).safeTransferFrom(_ERC721_Token.owner, msg.sender, serial_no, "");

      // Set status for the token slot
      NFTregistry.setNFTslotState(
        erc721_address, // ERC721 address
        serial_no, // Serial No.
        "CLAIMED", // Status
        remark, // Remarks
        meta // Meta
      );

      emit NFTswap(msg.sender, erc721_address, serial_no, $native, msg.value, block.timestamp);
    }
    
    function safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferBNB: BNB transfer failed"
        );
    }


    /**
    * @dev Contract Setup and Administrations
    */
    
    //
    // Change Contract Owner Address
    //
    function changeOwner(
        address new_address
    ) public onlyOwner {
        require(new_address != $owner && new_address != address(0), "E:[PM02]");
        $owner = new_address;
        transferOwnership($owner);
    }
    
    //
    // Change NFT registry.
    //
    function changeRegistry(
        address contract_address
    ) public onlyOwner {
        $nft_registry = contract_address;
        NFTregistry = NFT_Registry(contract_address);
    }


    /**
    * @dev Internal Utilities
    */

    //
    // Simply compare two strings.
    //
    function _compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }


    /**
    * @dev Error Codes
    *
    * E:[0000] Undefined error.
    *
    * E:[PM02] New owner address must not be the same as the current one.
    *
    * E:[TK20] ERC20 token was not active or registered.
    *
    * E:[TK21] ERC20 transfer was failed.
    *
    * E:[EX01] ERC721 amount was less than the required exchange rate.
    *
    * E:[EX02] ERC721 token slot was being reserved or already claimed.
    *
    *
    */
}


// Created by Jimmy IsraKhan <[email protected]>
// Latest update: 2021-09-25