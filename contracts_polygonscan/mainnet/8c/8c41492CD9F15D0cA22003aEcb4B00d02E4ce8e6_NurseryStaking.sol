// SPDX-License-Identifier: MIT

// Made for the GotchiWorld's Nursery

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

/**
 * @notice Used to know if petting is approved for an account
 */
interface IAavegotchiGameFacet {
    function isPetOperatorForAll(address _owner, address _operator) external view returns (bool approved_);
}

/**
 * @dev used to stake, unstake, keep track of frens and claim tickets
 */
interface IStakingFacet {
    function frens(address _account) external view returns (uint256 frens_);
    function stakeGhst(uint256 _ghstValue) external;
    function withdrawGhstStake(uint256 _ghstValue) external;
    function claimTickets(uint256[] calldata _ids, uint256[] calldata _values) external;
}

/**
 * @dev used to transfer tickets  
 */
interface ITicketsFacet {
    function safeBatchTransferFrom(address _from,address _to,uint256[] calldata _ids,uint256[] calldata _values,bytes calldata _data) external;
    function balanceOfAll(address _owner) external view returns (uint256[] memory balances_);
    function setApprovalForAll(address _operator, bool _approved) external;
}

/**
 * @dev Used to transfer GHST ERC20 Token (equi. IERC20)
 */
interface IGHSTFacet {
    function transferFrom(address _from,address _to,uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
}

contract NurseryStaking is Ownable, ERC1155Receiver {
    
    event AddMember(address _newMember);
    event RemoveMember(address _betrayer);
    
    uint256 private constant MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 private constant STAKING_FEES = 10 ** 18;
    uint256 private constant STAKING_AMOUNT = 99 * 10 ** 18;
    
    // Petting 
    address[] private _members;
    uint256 private _totalMembers;
    // Staking 
    uint256 private _collectedFees;
    
    // Contract addresses
    address public diamond;
    address public ghstDiamond;
    address public ghstERC20;
    // Petting Contract addresses
    address public petContract;
    
    // Interfaces to Aavegotchi contract - approval
    IAavegotchiGameFacet private immutable gameFacet;
    
    // Interfaces to Aavegotchi contract - Staking
    IStakingFacet private immutable stakingFacet;
    ITicketsFacet private immutable ticketsFacet;
    IGHSTFacet private immutable ghstFacet;
    
    // Mapping used to know the index of a member in the _members array
    // (memeber address => index id)
    mapping (address => uint256) public index;
    
    // Mapping used to know the current balance in Ghst 
    // (address owner => value)
    mapping (address => uint256) private _balances;

    constructor(address _diamond, address _ghstDiamond, address _ghstERC20, address _petContract) {
        diamond = _diamond;
        ghstDiamond = _ghstDiamond;
        ghstERC20 = _ghstERC20;
        petContract = _petContract;         
        gameFacet = IAavegotchiGameFacet(diamond); // is immutable
        stakingFacet = IStakingFacet(ghstDiamond); // is immutable
        ticketsFacet = ITicketsFacet(ghstDiamond); // is immutable
        ghstFacet = IGHSTFacet(ghstERC20);         // is immutable
        // total members 
        _totalMembers = 0;
        // first member is address 0 and index of leavers
        _addMember(0x86935F11C86623deC8a25696E1C19a8659CbF95d);
    }
    
    /************************************************
     * 
     *   USERS FUNCTIONS  
     * 
     ************************************************/
     
    /**
     * @notice Simple staking. You can only stake the STAKING_AMOUNT and that's it. Can't stake twice.
     */
    function stakeGhst() external {
        // Make sure member is not already staking (saving you 1GHST fees from mistakes)
        require(_balances[msg.sender] == 0, "Already staking");
        
        // Get the ghst from the account to the contract 
        ghstFacet.transferFrom(msg.sender, address(this), STAKING_AMOUNT);
        
        // Remove 1 GHST in staking fees that is added to the _collectedFees
        uint256 _stkValue = STAKING_AMOUNT - STAKING_FEES;
        _collectedFees += STAKING_FEES;
        
        // Stake from the contract to collect Frens 
        stakingFacet.stakeGhst(_stkValue);

        // Update the Balance of the msgsender 
        _balances[msg.sender] += _stkValue;
        
        // Add to the member array 
        _addMember(msg.sender);
    }
    
    /**
     * @notice Simple unstaking. You don't choose the amount, it unstake your balance 
     */
    function unstakeGhst() external {
        // Check if the account has enough ghst staked
        require(_balances[msg.sender] > 0, "Can't withdraw nothing");
        
        // Save balance of msgsender
        uint256 tempBalance = _balances[msg.sender];
        
        // Update the balance of msgsender  
        _balances[msg.sender] = 0;
        
        // Unstake from the contract 
        stakingFacet.withdrawGhstStake(tempBalance);
    
        // Send back the ghst to the msgsender
        ghstFacet.transfer(msg.sender, tempBalance);
        
        // Remove from member array
        _removeMember(msg.sender);
    }
    
    /************************************************
     * 
     *   ADMIN FUNCTIONS - STAKING  
     * 
     ************************************************/
    
    /**
     * @dev claim tickets then sends them to the owner. No this doesnt transfer your gotchi kek 
     */
    function claimTicketsAndWithdraw(uint256[] calldata _ids, uint256[] calldata _values) external onlyOwner {
        stakingFacet.claimTickets(_ids, _values);
        ticketsFacet.safeBatchTransferFrom(address(this), owner(), _ids, _values, "");
    }
    
    /**
     * @dev Withdraw collected 1 GHST Staking Fees
     */
    function withdrawCollectedFees() external onlyOwner {
        // tempCollectedFees prevent from calling multiple times the function to withdraw more ghst
        // This is not that useful as this contract doesn't have more than collected fees at any time
        uint256 tempCollectedFees = _collectedFees;
        _collectedFees = 0;
        ghstFacet.transfer(owner(), tempCollectedFees);
    }
    
    /**
     * @dev to be called during deploy, used to allow staking GHST in the main Aavegotchi contract
     */
    function approveGhst() external onlyOwner returns (bool) {
        return ghstFacet.approve(ghstDiamond,MAX_INT);
    }

    /************************************************
     * 
     *   PRIVATE FUNCTIONS - PETTING 
     * 
     ************************************************/
    
    /**
     * @dev Array used internaly to list all the accounts to pet. Called by stakeGhst()
     */
    function _addMember(address _newMember) private {
        // No need to add twice the same account
        require(index[_newMember] == 0,"Member already added");

        // Get the index where the new member is in the array 
        index[_newMember] = _members.length;

        // Push the data in the array 
        _members.push(_newMember);
        
        // increment the members counter 
        _totalMembers++;
        
        emit AddMember(_newMember);
    }
    
    /**
     * @dev Remove member, index it to 0, remove gaps. Called by unstakeGhst()
     */
    function _removeMember(address _addressLeaver) private {
        // Cant remove an account that is not a member
        require(index[_addressLeaver] != 0,"Member already removed");

        // Get the index of the leaver
        uint256 _indexLeaver = index[_addressLeaver];
        
        // Get last index
        uint256 lastElementIndex = _members.length - 1;
        
        // Get Last address in array 
        address lastAddressInArray = _members[lastElementIndex];
        
        // Move the last address in the position of the leaver 
        _members[_indexLeaver] = _members[lastElementIndex];
        
        // Change the moved address' index to the new one
        index[lastAddressInArray] = _indexLeaver;
        
        // Remove last entry in the array and reduce length
        _members.pop();
        index[_addressLeaver] = 0;
        
        // decrement the members counter 
        _totalMembers--;
        
        // this guy is ngmi 
        emit RemoveMember(_addressLeaver);
    }
    
    /************************************************
     * 
     *   VIEWS FUNCTION - members 
     * 
     ************************************************/
     
    function getMembers() external view returns (address[] memory) {
        return _members;
    }

    function totalMembers() external view returns (uint256) {
        return _totalMembers;
    }
    
    function getMembersIndexed(uint256 _pointer, uint256 _amount) external view returns (address[] memory) {
        address[] memory addresses = new address[](_amount);
        for (uint256 i = 0; i < _amount; i++) {
            uint256 pointer = _pointer + i;
            addresses[i] = _members[pointer];
        }
        return addresses;
    }
    
    function hasApprovedGotchiInteraction(address _account) public view returns (bool) {
        return gameFacet.isPetOperatorForAll(_account,petContract);
    }
    
    /************************************************
     * 
     *   VIEWS FUNCTION - STAKING 
     * 
     ************************************************/
     
    function hasStaked(address _account) public view returns (bool) {
        return _balances[_account] >= (STAKING_AMOUNT - STAKING_FEES);
    }
    
    function hasMembership(address _account) public view returns (bool) {
        return index[_account] > 0;
    }
    
    function collectedFees() external view returns (uint256) {
        return _collectedFees;
    }
    
    function stakingFees() external pure returns (uint256) {
        return STAKING_FEES;
    }
    
    function stakingAmount() external pure returns (uint256) {
        return STAKING_AMOUNT;
    }
    
    function stakedAmount() external view returns (uint256) {
        return _balances[msg.sender];
    }
    
    function contractFrensBalance() external view returns (uint256) {
        return stakingFacet.frens(address(this));
    }
        
    /************************************************
     * 
     *   VIEWS FUNCTION - BOTH 
     * 
     ************************************************/
     
    function shouldPet(address _member) external view returns (bool) {
        if(hasApprovedGotchiInteraction(_member) && hasStaked(_member) && hasMembership(_member)) {
            return true;
        }
        return false;
    }
    
    /************************************************
     * 
     *   ERC1155Receiver 
     * 
     ************************************************/
    /**
     * @dev both function in ERC1155Receiver are used so that the contract can own ERC1155 tokens
     */
    function onERC1155Received(
    address /*operator*/,
    address /*from*/,
    uint256 /*id*/,
    uint256 /*value*/,
    bytes calldata /*data*/
    )
    external
    pure
    override
    returns(bytes4)
    {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
    address /*operator*/,
    address /*from*/,
    uint256[] calldata /*ids*/,
    uint256[] calldata /*values*/,
    bytes calldata /*data*/
    )
    external
    pure
    override
    returns(bytes4)
    {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
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

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

