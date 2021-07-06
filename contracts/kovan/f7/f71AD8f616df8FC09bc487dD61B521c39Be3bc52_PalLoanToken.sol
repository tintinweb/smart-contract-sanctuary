//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
pragma abicoder v2;
//SPDX-License-Identifier: MIT

import "./PalLoanTokenInterface.sol";
import "./utils/ERC165.sol";
import "./utils/SafeMath.sol";
import "./utils/Admin.sol";
import "./PaladinControllerInterface.sol";
import "./BurnedPalLoanToken.sol";
import {Errors} from  "./utils/Errors.sol";

/** @title palLoanToken contract  */
/// @author Paladin
contract PalLoanToken is PalLoanTokenInterface, ERC165, Admin {
    using SafeMath for uint;

    //Storage

    // Token name
    string public name;

    // Token symbol
    string public symbol;

    //Incremental index for next token ID
    uint256 private index;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private owners;

    // Mapping owner address to token count
    mapping(address => uint256) private balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private approvals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private operatorApprovals;

    // Paladin controller
    PaladinControllerInterface public controller;

    // Burned Token contract
    BurnedPalLoanToken public burnedToken;

    // Mapping from token ID to origin PalPool
    mapping(uint256 => address) private pools;

    // Mapping from token ID to PalLoan address
    mapping(uint256 => address) private loans;




    //Modifiers
    modifier controllerOnly() {
        //allows only the Controller and the admin to call the function
        require(msg.sender == admin || msg.sender == address(controller), Errors.CALLER_NOT_CONTROLLER);
        _;
    }

    modifier poolsOnly() {
        //allows only a PalPool listed in the Controller
        require(controller.isPalPool(msg.sender), Errors.CALLER_NOT_ALLOWED_POOL);
        _;
    }



    //Constructor
    constructor(address _controller) {
        admin = msg.sender;

        // ERC721 parameters + storage data
        name = "PalLoan Token";
        symbol = "PLT";
        controller = PaladinControllerInterface(_controller);
        index = 0;

        //Create the Burned version of this ERC721
        burnedToken = new BurnedPalLoanToken("burnedPalLoan Token", "bPLT");
    }


    //Functions

    //Required ERC165 function
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }



    /**
    * @notice Return the user balance (total number of token owned)
    * @param owner Address of the user
    * @return uint256 : number of token owned (in this contract only)
    */
    function balanceOf(address owner) external view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return balances[owner];
    }


    /**
    * @notice Return owner of the token
    * @param tokenId Id of the token
    * @return address : owner address
    */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }


    /**
    * @notice Return owner of the token, even is the token was burned 
    * @dev Check if the given id has an owner in this contract, and then if it was burned and has an owner
    * @param tokenId Id of the token
    * @return address : address of the owner
    */
    function allOwnerOf(uint256 tokenId) external view override returns (address) {
        require(tokenId < index, "ERC721: owner query for nonexistent token");
        return owners[tokenId] != address(0) ? owners[tokenId] : burnedToken.ownerOf(tokenId);
    }


    /**
    * @notice Return the address of the palLoan for this token
    * @param tokenId Id of the token
    * @return address : address of the palLoan
    */
    function loanOf(uint256 tokenId) external view override returns(address){
        return loans[tokenId];
    }


    /**
    * @notice Return the palPool that issued this token
    * @param tokenId Id of the token
    * @return address : address of the palPool
    */
    function poolOf(uint256 tokenId) external view override returns(address){
        return pools[tokenId];
    }

    
    /**
    * @notice Return the list of all active palLoans owned by the user
    * @dev Find all the token owned by the user, and return the list of palLoans linked to the found tokens
    * @param owner User address
    * @return address[] : list of owned active palLoans
    */
    function loansOf(address owner) external view override returns(address[] memory){
        require(index > 0);
        uint256 tokenCount = balances[owner];
        uint256 j = 0;
        address[] memory result = new address[](tokenCount);
        for(uint256 id = 0; id < index; id++){
            if(owners[id] == owner){
                result[j] = loans[id];
                j++;
            }   
        }
        return result;
    }


    /**
    * @notice Return the list of all tokens owned by the user
    * @dev Find all the token owned by the user
    * @param owner User address
    * @return uint256[] : list of owned tokens
    */
    function tokensOf(address owner) external view override returns(uint256[] memory){
        require(index > 0);
        uint256 tokenCount = balances[owner];
        uint256 j = 0;
        uint256[] memory result = new uint256[](tokenCount);
        for(uint256 id = 0; id < index; id++){
            if(owners[id] == owner){
                result[j] = id;
                j++;
            }   
        }
        return result;
    }


    /**
    * @notice Return the list of all active palLoans owned by the user for the given palPool
    * @dev Find all the token owned by the user issued by the given Pool, and return the list of palLoans linked to the found tokens
    * @param owner User address
    * @return address[] : list of owned active palLoans for the given palPool
    */
    function loansOfForPool(address owner, address palPool) external view override returns(address[] memory){
        require(index > 0);
        uint256 tokenCount = balances[owner];
        uint256 j = 0;
        //go through all the id to find the ones for the owner, from the given pool
        address[] memory result = new address[](tokenCount);
        for(uint256 id = 0; id < index; id++){
            if(owners[id] == owner && pools[id] == palPool){
                result[j] = loans[id];
                j++;
            }   
        }

        //put the result in a new array with correct size to avoid 0x00 addresses in the return array
        address[] memory filteredResult = new address[](j);
        for(uint256 i = 0; i < j; i++){
            filteredResult[i] = result[i];   
        }

        return filteredResult;
    }


    /**
    * @notice Return the list of all tokens owned by the user
    * @dev Find all the token owned by the user (in this contract and in the Burned contract)
    * @param owner User address
    * @return uint256[] : list of owned tokens
    */
    function allTokensOf(address owner) external view override returns(uint256[] memory){
        require(index > 0);
        uint256 tokenCount = balances[owner].add(burnedToken.balanceOf(owner));
        uint256 j = 0;
        uint256[] memory result = new uint256[](tokenCount);
        for(uint256 id = 0; id < index; id++){
            if(owners[id] == owner){
                result[j] = id;
                j++;
            }   
        }

        //get the burned Tokens for the owner and add them to the array
        uint256[] memory burnedTokens = burnedToken.tokensOf(owner);
        for(uint256 i = j; i < tokenCount; i++){
            result[i] = burnedTokens[i.sub(j)];
        }

        return result;
    }


    /**
    * @notice Return the list of all palLoans (active and closed) owned by the user
    * @dev Find all the token owned by the user, and all the burned tokens owned by the user,
    * and return the list of palLoans linked to the found tokens
    * @param owner User address
    * @return address[] : list of owned palLoans
    */
    function allLoansOf(address owner) external view override returns(address[] memory){
        require(index > 0);
        uint256 tokenCount = balances[owner].add(burnedToken.balanceOf(owner));
        uint256 j = 0;
        //go through all the id to find the ones for the owner, from the given pool
        address[] memory result = new address[](tokenCount);
        for(uint256 id = 0; id < index; id++){
            if(owners[id] == owner){
                result[j] = loans[id];
                j++;
            }   
        }

        //get the burned Tokens for the owner and add them to the array
        uint256[] memory burnedTokens = burnedToken.tokensOf(owner);
        for(uint256 i = j; i < tokenCount; i++){
            result[i] = loans[burnedTokens[i.sub(j)]];
        }

        return result;
    }


    /**
    * @notice Return the list of all palLoans owned by the user for the given palPool
    * @dev Find all the token owned by the user issued by the given Pool, and return the list of palLoans linked to the found tokens
    * @param owner User address
    * @return address[] : list of owned palLoans (active & closed) for the given palPool
    */
    function allLoansOfForPool(address owner, address palPool) external view override returns(address[] memory){
        require(index > 0);
        uint256 tokenCount = balances[owner].add(burnedToken.balanceOf(owner));
        uint256 j = 0;
        //go through all the id to find the ones for the owner, from the given pool
        address[] memory result = new address[](tokenCount);
        for(uint256 id = 0; id < index; id++){
            if(owners[id] == owner && pools[id] == palPool){
                result[j] = loans[id];
                j++;
            }   
        }

        //get the burned Tokens for the owner and add them to the array
        uint256[] memory burnedTokens = burnedToken.tokensOf(owner);
        for(uint256 i = 0; i < burnedTokens.length; i++){
            if(pools[burnedTokens[i]] == palPool){
                result[j] = loans[burnedTokens[i]];
                j++;
            }
        }

        //put the result in a new array with correct size to avoid 0x00 addresses in the return array
        address[] memory filteredResult = new address[](j);
        for(uint256 k = 0; k < j; k++){
            filteredResult[k] = result[k];   
        }

        return filteredResult;
    }


    /**
    * @notice Check if the token was burned
    * @param tokenId Id of the token
    * @return bool : true if burned
    */
    function isBurned(uint256 tokenId) external view override returns(bool){
        return burnedToken.ownerOf(tokenId) != address(0);
    }





    /**
    * @notice Approve the address to spend the token
    * @param to Address of the spender
    * @param tokenId Id of the token to approve
    */
    function approve(address to, uint256 tokenId) external virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }


    /**
    * @notice Return the approved address for the token
    * @param tokenId Id of the token
    * @return address : spender's address
    */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return approvals[tokenId];
    }


    /**
    * @notice Give the operator approval on all tokens owned by the user, or remove it by setting it to false
    * @param operator Address of the operator to approve
    * @param approved Boolean : give or remove approval
    */
    function setApprovalForAll(address operator, bool approved) external virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");

        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }


    /**
    * @notice Return true if the operator is approved for the given user
    * @param owner Amount of the owner
    * @param operator Address of the operator
    * @return bool :  result
    */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return operatorApprovals[owner][operator];
    }







    /**
    * @notice Transfer the token from the owner to the recipient (if allowed)
    * @param from Address of the owner
    * @param to Address of the recipient
    * @param tokenId Id of the token
    */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }


    /**
    * @notice Safe transfer the token from the owner to the recipient (if allowed)
    * @param from Address of the owner
    * @param to Address of the recipient
    * @param tokenId Id of the token
    */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        require(_transfer(from, to, tokenId), "ERC721: transfer failed");
    }


    /**
    * @notice Safe transfer the token from the owner to the recipient (if allowed)
    * @param from Address of the owner
    * @param to Address of the recipient
    * @param tokenId Id of the token
    */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external virtual override {
        _data;
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        require(_transfer(from, to, tokenId), "ERC721: transfer failed");
    }






    /**
    * @notice Mint a new token to the given address
    * @dev Mint the new token, and list it with the given palLoan and palPool
    * @param to Address of the user to mint the token to
    * @param palPool Address of the palPool issuing the token
    * @param palLoan Address of the palLoan linked to the token
    * @return uint256 : new token Id
    */
    function mint(address to, address palPool, address palLoan) external override poolsOnly returns(uint256){
        require(palLoan != address(0), Errors.ZERO_ADDRESS);

        //Call the internal mint method, and get the new token Id
        uint256 newId = _mint(to);

        //Set the correct data in mappings for this token
        loans[newId] = palLoan;
        pools[newId] = palPool;

        //Emit the Mint Event
        emit NewLoanToken(palPool, to, palLoan, newId);

        //Return the new token Id
        return newId;
    }


    /**
    * @notice Burn the given token
    * @dev Burn the token, and mint the BurnedToken for this token
    * @param tokenId Id of the token to burn
    * @return bool : success
    */
    function burn(uint256 tokenId) external override poolsOnly returns(bool){
        address owner = ownerOf(tokenId);

        require(owner != address(0), "ERC721: token nonexistant");

        //Mint the Burned version of this token
        burnedToken.mint(owner, tokenId);

        //Emit the correct event
        emit BurnLoanToken(pools[tokenId], owner, loans[tokenId], tokenId);

        //call the internal burn method
        return _burn(owner, tokenId);
    }

    

    



    /**
    * @notice Check if a token exists
    * @param tokenId Id of the token
    * @return bool : treu if token exists (active or burned)
    */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return owners[tokenId] != address(0) || burnedToken.ownerOf(tokenId) != address(0);
    }


    /**
    * @notice Check if the given user is approved for the given token
    * @param spender Address of the user to check
    * @param tokenId Id of the token
    * @return bool : true if approved
    */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }





    /**
    * @notice Mint the new token
    * @param to Address of the user to mint the token to
    * @return uint : Id of the new token
    */
    function _mint(address to) internal virtual returns(uint) {
        require(to != address(0), "ERC721: mint to the zero address");

        //Get the new token Id, and increase the global index
        uint tokenId = index;
        index = index.add(1);

        //Write this token in the storage
        balances[to] = balances[to].add(1);
        owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        //Return the new token Id
        return tokenId;
    }


    /**
    * @notice Burn the given token
    * @param owner Address of the token owner
    * @param tokenId Id of the token to burn
    * @return bool : success
    */
    function _burn(address owner, uint256 tokenId) internal virtual returns(bool) {
        //Reset the token approval
        _approve(address(0), tokenId);

        //Update data in storage
        balances[owner] = balances[owner].sub(1);
        delete owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        return true;
    }


    /**
    * @notice Transfer the token from the owner to the recipient
    * @dev Deposit underlying, and mints palToken for the user
    * @param from Address of the owner
    * @param to Address of the recipient
    * @param tokenId Id of the token
    * @return bool : success
    */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual returns(bool) {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        //Reset token approval
        _approve(address(0), tokenId);

        //Update storage data
        balances[from] = balances[from].sub(1);
        balances[to] = balances[to].add(1);
        owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        return true;
    }


    /**
    * @notice Approve the given address to spend the token
    * @param to Address to approve
    * @param tokenId Id of the token to approve
    */
    function _approve(address to, uint256 tokenId) internal virtual {
        approvals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }



    //Admin functions
    /**
    * @notice Set a new Controller
    * @dev Loads the new Controller for the Pool
    * @param  _newController address of the new Controller
    */
    function setNewController(address _newController) external override controllerOnly {
        controller = PaladinControllerInterface(_newController);
    }

}

//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
pragma abicoder v2;
//SPDX-License-Identifier: MIT

import "./utils/IERC721.sol";

/** @title palLoanToken Interface  */
/// @author Paladin
interface PalLoanTokenInterface is IERC721 {

    //Events

    /** @notice Event when a new Loan Token is minted */
    event NewLoanToken(address palPool, address indexed owner, address indexed palLoan, uint256 indexed tokenId);
    /** @notice Event when a Loan Token is burned */
    event BurnLoanToken(address palPool, address indexed owner, address indexed palLoan, uint256 indexed tokenId);


    //Functions
    function mint(address to, address palPool, address palLoan) external returns(uint256);
    function burn(uint256 tokenId) external returns(bool);

    function loanOf(uint256 tokenId) external view returns(address);
    function poolOf(uint256 tokenId) external view returns(address);
    function loansOf(address owner) external view returns(address[] memory);
    function tokensOf(address owner) external view returns(uint256[] memory);
    function loansOfForPool(address owner, address palPool) external view returns(address[] memory);
    function allTokensOf(address owner) external view returns(uint256[] memory);
    function allLoansOf(address owner) external view returns(address[] memory);
    function allLoansOfForPool(address owner, address palPool) external view returns(address[] memory);
    function allOwnerOf(uint256 tokenId) external view returns(address);

    function isBurned(uint256 tokenId) external view returns(bool);

    //Admin functions
    function setNewController(address _newController) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

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

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

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
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

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
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        require(c / a == b, "SafeMath: multiplication overflow");

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
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        return div(a, b, "SafeMath: division by zero");
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT


/** @title Admin contract  */
/// @author Paladin
contract Admin {

    /** @notice (Admin) Event when the contract admin is updated */
    event NewAdmin(address oldAdmin, address newAdmin);

    /** @dev Admin address for this contract */
    address payable internal admin;
    
    modifier adminOnly() {
        //allows onyl the admin of this contract to call the function
        require(msg.sender == admin, '1');
        _;
    }

        /**
    * @notice Set a new Admin
    * @dev Changes the address for the admin parameter
    * @param _newAdmin address of the new Controller Admin
    */
    function setNewAdmin(address payable _newAdmin) external adminOnly {
        address _oldAdmin = admin;
        admin = _newAdmin;

        emit NewAdmin(_oldAdmin, _newAdmin);
    }
}

//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

/** @title Paladin Controller Interface  */
/// @author Paladin
interface PaladinControllerInterface {
    
    //Events

    /** @notice Event emitted when a new token & pool are added to the list */
    event NewPalPool(address palPool);

    /** @notice Event emitted when the contract admni is updated */
    event NewAdmin(address oldAdmin, address newAdmin);


    //Functions
    function isPalPool(address _pool) external view returns(bool);
    function getPalTokens() external view returns(address[] memory);
    function getPalPools() external view returns(address[] memory);
    function setInitialPools(address[] memory _palTokens, address[] memory _palPools) external returns(bool);
    function addNewPool(address _palToken, address _palPool) external returns(bool);

    function withdrawPossible(address palPool, uint amount) external view returns(bool);
    function borrowPossible(address palPool, uint amount) external view returns(bool);

    function depositVerify(address palPool, address dest, uint amount) external view returns(bool);
    function withdrawVerify(address palPool, address dest, uint amount) external view returns(bool);
    function borrowVerify(address palPool, address borrower, address delegatee, uint amount, uint feesAmount, address loanPool) external view returns(bool);
    function closeBorrowVerify(address palPool, address borrower, address loanPool) external view returns(bool);
    function killBorrowVerify(address palPool, address killer, address loanPool) external view returns(bool);

    //Admin functions
    function setNewAdmin(address payable _newAdmin) external returns(bool);
    function setPoolsNewController(address _newController) external returns(bool);
    function removeReserveFromPool(address _pool, uint _amount, address _recipient) external returns(bool);
    function removeReserveFromAllPools(address _recipient) external returns(bool);

}

//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
pragma abicoder v2;
//SPDX-License-Identifier: MIT

import {Errors} from  "./utils/Errors.sol";
import "./utils/SafeMath.sol";



/** @title bPalLoanToken contract  */
/// @author Paladin
contract BurnedPalLoanToken{
    using SafeMath for uint;

    //Storage

    // Token name
    string public name;
    // Token symbol
    string public symbol;

    address public minter;

    uint256 public totalSupply;
    // Mapping from token ID to owner address
    mapping(uint256 => address) private owners;

    // Mapping owner address to token count
    mapping(address => uint256[]) private balances;


    //Modifiers
    modifier authorized() {
        //allows only the palLoanToken contract to call methds
        require(msg.sender == minter, Errors.CALLER_NOT_MINTER);
        _;
    }


    //Events

    /** @notice Event when a new token is minted */
    event NewBurnedLoanToken(address indexed to, uint256 indexed tokenId);


    //Constructor
    constructor(string memory _name, string memory _symbol) {
        //ERC721 parameters
        name = _name;
        symbol = _symbol;
        minter = msg.sender;
        totalSupply = 0;
    }



    //Functions


    /**
    * @notice Return the user balance (total number of token owned)
    * @param owner Address of the user
    * @return uint256 : number of token owned (in this contract only)
    */
    function balanceOf(address owner) external view returns (uint256){
        require(owner != address(0), "ERC721: balance query for the zero address");
        return balances[owner].length;
    }


    /**
    * @notice Return owner of the token
    * @param tokenId Id of the token
    * @return address : owner address
    */
    function ownerOf(uint256 tokenId) external view returns (address){
        return owners[tokenId];
    }

    
    /**
    * @notice Return the list of all tokens owned by the user
    * @dev Return the list of user's tokens
    * @param owner User address
    * @return uint256[] : list of owned tokens
    */
    function tokensOf(address owner) external view returns(uint256[] memory){
        return balances[owner];
    }

    

    /**
    * @notice Mint a new token to the given address with the given Id
    * @dev Mint the new token with the correct Id (from the previous burned token)
    * @param to Address of the user to mint the token to
    * @param tokenId Id of the token to mint
    * @return bool : success
    */
    function mint(address to, uint256 tokenId) external returns(bool){
        require(to != address(0), "ERC721: mint to the zero address");

        //Update Supply
        totalSupply = totalSupply.add(1);

        //Add the new token to storage
        balances[to].push(tokenId);
        owners[tokenId] = to;

        //Emit the correct Event
        emit NewBurnedLoanToken(to, tokenId);

        return true;
    }


}

//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

library Errors {
    // Admin error
    string public constant CALLER_NOT_ADMIN = '1'; // 'The caller must be the admin'
    string public constant CALLER_NOT_CONTROLLER = '29'; // 'The caller must be the admin or the controller'
    string public constant CALLER_NOT_ALLOWED_POOL = '30';  // 'The caller must be a palPool listed in tle controller'
    string public constant CALLER_NOT_MINTER = '31';

    // ERC20 type errors
    string public constant FAIL_TRANSFER = '2';
    string public constant FAIL_TRANSFER_FROM = '3';
    string public constant BALANCE_TOO_LOW = '4';
    string public constant ALLOWANCE_TOO_LOW = '5';
    string public constant SELF_TRANSFER = '6';

    // PalPool errors
    string public constant INSUFFICIENT_CASH = '9';
    string public constant INSUFFICIENT_BALANCE = '10';
    string public constant FAIL_DEPOSIT = '11';
    string public constant FAIL_LOAN_INITIATE = '12';
    string public constant FAIL_BORROW = '13';
    string public constant ZERO_BORROW = '27';
    string public constant BORROW_INSUFFICIENT_FEES = '23';
    string public constant LOAN_CLOSED = '14';
    string public constant NOT_LOAN_OWNER = '15';
    string public constant LOAN_OWNER = '16';
    string public constant FAIL_LOAN_EXPAND = '17';
    string public constant NOT_KILLABLE = '18';
    string public constant RESERVE_FUNDS_INSUFFICIENT = '19';
    string public constant FAIL_MINT = '20';
    string public constant FAIL_BURN = '21';
    string public constant FAIL_WITHDRAW = '24';
    string public constant FAIL_CLOSE_BORROW = '25';
    string public constant FAIL_KILL_BORROW = '26';
    string public constant ZERO_ADDRESS = '22';
    string public constant INVALID_PARAMETERS = '28'; 
    string public constant FAIL_LOAN_DELEGATEE_CHANGE = '32';
    string public constant FAIL_LOAN_TOKEN_BURN = '33';

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

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

{
  "optimizer": {
    "enabled": true,
    "runs": 25000
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
  "libraries": {}
}