/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

/**
 *Submitted for verification at Etherscan.io on 2019-04-11
*/

//
// FormSI060719, which is part of the show "Garage Politburo" at Susan Inglett Gallery, NY.
// June 7, 2019 - July 26, 2019

// For more information see https://github.com/GaragePolitburo/FormSI060719

// Based on code by OpenZeppelin: 
// https://github.com/OpenZeppelin/openzeppelin-solidity/tree/master/contracts/token/ERC721
// Used Jan 4 2019 Open Zepplin package 76abd1a41ec7d96ef76370f3eadfe097226896a2

// Based also on CryptoPunks by Larva Labs:
// https://github.com/larvalabs/cryptopunks

// Text snippets taken from Fredric Jameson, Masha Gessen, Nisi Shawl, Margaret Thatcher, 
//  Leni Zumas, Philip Roth, Omar El Akkad, Wayne La Pierre, David Graeber,
// Walt Whitman, George Orwell, Rudyard Kipling, and Donna Haraway.


pragma solidity ^0.5.0;

/**
 * @title IERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {
    /**
     * @notice Query if a contract implements an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @title ERC165
 * @author Matt Condon (@shrugs)
 * @dev Implements ERC165 using a lookup table.
 */
contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    /**
     * 0x01ffc9a7 ===
     *     bytes4(keccak256('supportsInterface(bytes4)'))
     */

    /**
     * @dev a mapping of interface id to whether or not it's supported
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev A contract implementing SupportsInterfaceWithLookup
     * implement ERC165 itself
     */
    constructor () internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev implement supportsInterface(bytes4) using a lookup table
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev internal method for registering an interface
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}



/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */

contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);

    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a `safeTransfer`. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}


/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract FormSI060719 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to owner
    mapping (uint256 => address) private _tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping (address => uint256) private _ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    /*
     * 0x80ac58cd ===
     *     bytes4(keccak256('balanceOf(address)')) ^
     *     bytes4(keccak256('ownerOf(uint256)')) ^
     *     bytes4(keccak256('approve(address,uint256)')) ^
     *     bytes4(keccak256('getApproved(uint256)')) ^
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) ^
     *     bytes4(keccak256('isApprovedForAll(address,address)')) ^
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) ^
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'))
     */

    // FORM
    string private _name = "FormSI060719 :: Garage Politburo Tokens";
    string private _symbol = "SIGP";
    string[] private _theFormSI060719;
    uint256[2][] private _theIndexToQA; //tokeId gives (questionId, textId)
    uint256[][13] private _theQAtoIndex; // [questionId, textid] gives tokenId
    uint256 private _totalSupply; 
    uint256[13] private _supplyPerQ; 
    uint256 public numberOfQuestions = 13;
    string[] private _qSection;
    string private _qForm;

    
    // END FORM
    
    //AUCTION
     
    // Put list element up for sale by owner. Can be linked to specific 
    // potential buyer
    struct forSaleInfo {
        bool isForSale;
        uint256 tokenId;
        address seller;
        uint256 minValue;          //in wei.... everything in wei
        address onlySellTo;     // specify to sell only to a specific person
    }

    // Place bid for specific list element
    struct bidInfo {
        bool hasBid;
        uint256 tokenId;
        address bidder;
        uint256 value;
    }

    // Public info about tokens for sale.
    mapping (uint256 => forSaleInfo) public marketForSaleInfoByIndex;
    // Public info about highest bid for each token.
    mapping (uint256 => bidInfo) public marketBidInfoByIndex;
    // Information about withdrawals (in units of wei) available  
    //  ... for addresses due to failed bids, successful sales, etc...
    mapping (address => uint256) public marketPendingWithdrawals;
    
    //END AUCTION
    
    //EVENTS
    
    // In addition to Transfer, Approval, and ApprovalForAll IERC721 events
    event QuestionAnswered(uint256 indexed questionId, uint256 indexed answerId, 
        address indexed by);
    event ForSaleDeclared(uint256 indexed tokenId, address indexed from, 
        uint256 minValue,address indexed to);
    event ForSaleWithdrawn(uint256 indexed tokenId, address indexed from);
    event ForSaleBought(uint256 indexed tokenId, uint256 value, 
        address indexed from, address indexed to);
    event BidDeclared(uint256 indexed tokenId, uint256 value, 
        address indexed from);
    event BidWithdrawn(uint256 indexed tokenId, uint256 value, 
        address indexed from);
    event BidAccepted(uint256 indexed tokenId, uint256 value, 
        address indexed from, address indexed to);
    
    //END EVENTS

    constructor () public {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _qForm = "FormSI060719 :: freeAssociationAndResponse :: ";
        _qSection.push("Section 0-2b :: ");
        _qSection.push("Section2-TINA :: ");
        _qSection.push("Section2b-WS :: ");
 

        _theFormSI060719.push("When we ask ourselves \"How are we?\" :: we really want to know ::");
        _theQAtoIndex[0].push(0);
        _theIndexToQA.push([0,0]);
        _tokenOwner[0] = msg.sender;
        _ownedTokensCount[msg.sender] = _ownedTokensCount[msg.sender].add(1);
        _supplyPerQ[0] = 1;

        _theFormSI060719.push("How are we to ensure equitable merit-based access? :: Tried to cut down :: used more than intended :: ");
        _theQAtoIndex[1].push(1);
        _theIndexToQA.push([1,0]);
        _tokenOwner[1] = msg.sender;
        _ownedTokensCount[msg.sender] = _ownedTokensCount[msg.sender].add(1);
        _supplyPerQ[1] = 1;

        _theFormSI060719.push("Psychoanalytic Placement Bureau ::");
        _theQAtoIndex[2].push(2);
        _theIndexToQA.push([2,0]);
        _tokenOwner[2] = msg.sender;
        _ownedTokensCount[msg.sender] = _ownedTokensCount[msg.sender].add(1);
        _supplyPerQ[2] = 1;

        _theFormSI060719.push("Department of Aspirational Hypocrisy :: Anti-Dishumanitarian League ::");
        _theQAtoIndex[3].push(3);
        _theIndexToQA.push([3,0]);
        _tokenOwner[3] = msg.sender;
        _ownedTokensCount[msg.sender] = _ownedTokensCount[msg.sender].add(1);
        _supplyPerQ[3] = 1;

        _theFormSI060719.push("Personhood Amendment :: Homestead 42 ::");
        _theQAtoIndex[4].push(4);
        _theIndexToQA.push([4,0]);
        _tokenOwner[4] = msg.sender;
        _ownedTokensCount[msg.sender] = _ownedTokensCount[msg.sender].add(1);
        _supplyPerQ[4] = 1;

        _theFormSI060719.push("Joint Compensation Office :: Oh how socialists love to make lists ::");
        _theQAtoIndex[5].push(5);
        _theIndexToQA.push([5,0]);
        _tokenOwner[5] = msg.sender;
        _ownedTokensCount[msg.sender] = _ownedTokensCount[msg.sender].add(1);
        _supplyPerQ[5] = 1;

        _theFormSI060719.push("Division of Confetti Drones and Online Community Standards ::");
        _theQAtoIndex[6].push(6);
        _theIndexToQA.push([6,0]);
        _tokenOwner[6] = msg.sender;
        _ownedTokensCount[msg.sender] = _ownedTokensCount[msg.sender].add(1);
        _supplyPerQ[6] = 1;

        _theFormSI060719.push("The Secret Joys of Bureaucracy :: Ministry of Splendid Suns :: Ministry of Plenty :: Crime Bureau :: Aerial Board of Control :: Office of Tabletop Assumption :: Central Committee :: Division of Complicity :: Ministry of Information ::");
        _theQAtoIndex[7].push(7);
        _theIndexToQA.push([7,0]);
        _tokenOwner[7] = msg.sender;
        _ownedTokensCount[msg.sender] = _ownedTokensCount[msg.sender].add(1);
        _supplyPerQ[7] = 1;

        _theFormSI060719.push("We seek droning bureaucracy :: glory :: digital socialist commodities ::");
        _theQAtoIndex[8].push(8);
        _theIndexToQA.push([8,0]);
        _tokenOwner[8] = msg.sender;
        _ownedTokensCount[msg.sender] = _ownedTokensCount[msg.sender].add(1);
        _supplyPerQ[8] = 1;

        _theFormSI060719.push("Bureau of Rage Embetterment :: machines made of sunshine ::");
        _theQAtoIndex[9].push(9);
        _theIndexToQA.push([9,0]);
        _tokenOwner[9] = msg.sender;
        _ownedTokensCount[msg.sender] = _ownedTokensCount[msg.sender].add(1);
        _supplyPerQ[9] = 1;

        _theFormSI060719.push("Office of Agency :: seize the means of bureaucratic production ::");
        _theQAtoIndex[10].push(10);
        _theIndexToQA.push([10,0]);
        _tokenOwner[10] = msg.sender;
        _ownedTokensCount[msg.sender] = _ownedTokensCount[msg.sender].add(1);
        _supplyPerQ[10] = 1;

        _theFormSI060719.push("Garage Politburo :: Boutique Ministry ::");
        _theQAtoIndex[11].push(11);
        _theIndexToQA.push([11,0]);
        _tokenOwner[11] = msg.sender;
        _ownedTokensCount[msg.sender] = _ownedTokensCount[msg.sender].add(1);
        _supplyPerQ[11] = 1;

        _theFormSI060719.push("Grassroots :: Tabletop :: Bureaucracy Saves! ::"); 
        _theQAtoIndex[12].push(12);
        _theIndexToQA.push([12,0]);
        _tokenOwner[12] = msg.sender;
        _ownedTokensCount[msg.sender] = _ownedTokensCount[msg.sender].add(1);
        _supplyPerQ[12] = 1;

        _totalSupply = 13;
        assert (_totalSupply == numberOfQuestions);
        assert (_totalSupply == _ownedTokensCount[msg.sender]);
        
    }

    //Begin Form


    function name() external view returns (string memory){
       return _name;
    }

    function totalSupply() external view returns (uint256){
       return _totalSupply;
    }


    function symbol() external view returns (string memory){
       return _symbol;
    }


    // questionId goes from 0 to numberOfQuestions - 1    
    function getFormQuestion(uint256 questionId)
        public view
        returns (string memory){
            
        return (_getQAtext(questionId, 0));
            
    }
    
    // questionId goes from 0 to numberOfQuestions - 1  
    // answerId goes from 1 to _supplyPerQ - 1
    // If there are no answers to questionId, this function reverts
    function getFormAnswers(uint256 questionId, uint256 answerId)
        public view
        returns (string memory){
            
        require (answerId > 0);
        return (_getQAtext(questionId, answerId));
            
    }    

 
    function _getQAtext(uint256 questionId, uint256 textId)
        private view 
        returns (string memory){
    
        require (questionId < numberOfQuestions);
        require (textId < _supplyPerQ[questionId]);
       
        if (textId > 0){
          return (_theFormSI060719[_theQAtoIndex[questionId][textId]]);
        }

        else {
            bytes memory qPrefix;
            if (questionId <= 1) {
                qPrefix = bytes(_qSection[0]);
            }
            if ((questionId >= 2) && (questionId <= 6)){
                qPrefix = bytes(_qSection[1]);
            }
            if (questionId >= 7){
                qPrefix = bytes(_qSection[2]);
            }
            return (string(abi.encodePacked(bytes(_qForm), qPrefix, 
                bytes(_theFormSI060719[_theQAtoIndex[questionId][textId]]))));
        }
            
    }
      
     function answerQuestion(uint256 questionId, string calldata answer)
        external
        returns (bool){

        require (questionId < numberOfQuestions);
        require (bytes(answer).length != 0);
        _theFormSI060719.push(answer);
        _totalSupply = _totalSupply.add(1);
        _supplyPerQ[questionId] = _supplyPerQ[questionId].add(1);
        _theQAtoIndex[questionId].push(_totalSupply - 1);
        _theIndexToQA.push([questionId, _supplyPerQ[questionId] - 1]);
        _tokenOwner[_totalSupply - 1] = msg.sender;
        _ownedTokensCount[msg.sender] = _ownedTokensCount[msg.sender].add(1);
        emit QuestionAnswered(questionId, _supplyPerQ[questionId] - 1,
            msg.sender);
       return true;
    }
    
    // Returns index of ERC721 token
    // questionId start with index 0
    // textId 0 returns the question text associated with questionId
    // textId 1 returns the first answer to questionId, etc...
    function getIndexfromQA(uint256 questionId, uint256 textId)
        public view
        returns (uint256) {
            
        require (questionId < numberOfQuestions);
        require (textId < _supplyPerQ[questionId]);
        return _theQAtoIndex[questionId][textId];
    }

    // Returns (questionId, textId) 
    // questionId starts with index 0
    // textId starts with index 0
    // textId = 0 corresponds to question text
    // textId > 0 corresponts to answers
    
    function getQAfromIndex(uint256 tokenId)
        public view
        returns (uint256[2] memory) {
            
        require (tokenId < _totalSupply);
        return ([_theIndexToQA[tokenId][0] ,_theIndexToQA[tokenId][1]]) ;
    }
        
    function getNumberOfAnswers(uint256 questionId)
        public view
        returns (uint256){
        
        require (questionId < numberOfQuestions);
        return (_supplyPerQ[questionId] - 1);
        
    }
    //End Form

 
    /**
     * @dev Gets the balance of the specified address
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0));
        return _ownedTokensCount[owner];
    }

    /**
     * @dev Gets the owner of the specified token ID
     * @param tokenId uint256 ID of the token to query the owner of
     * @return owner address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0));
        return owner;
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId));
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender);
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address
     * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
     * Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
    */
    function transferFrom(address from, address to, uint256 tokenId) public {
        // this checks if token exists
        require(_isApprovedOrOwner(msg.sender, tokenId));

        // remove for sale, if it exists.
        if (marketForSaleInfoByIndex[tokenId].isForSale){
            marketForSaleInfoByIndex[tokenId] = forSaleInfo(false, tokenId, 
             address(0), 0, address(0));
            emit ForSaleWithdrawn(tokenId, _tokenOwner[tokenId]);
        }
        _transferFrom(from, to, tokenId);
        
        // remove bid of recipient (and now new owner), if it exists.
        // Need to do this since marketWithdrawBid requires that msg.sender not owner.
        if (marketBidInfoByIndex[tokenId].bidder == to){
            _clearNewOwnerBid(to, tokenId);
        }
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     *
     * Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
    */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data));
    }

    /**
     * @dev Returns whether the specified token exists
     * @param tokenId uint256 ID of the token to query the existence of
     * @return whether the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     *    is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }



    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to transferFrom, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
    */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from);
        require(to != address(0));

        _clearApproval(tokenId);

        _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to invoke `onERC721Received` on a target address
     * The call is not executed if the target address is not a contract
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Private function to clear current approval of a given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
    
        //MARKET

    // Let anyone interested know that the owner put a token up for sale. 
    // Anyone can obtain it by sending an amount of wei equal to or
    // larger than  _minPriceInWei. 
    // Only token owner can use this function.

    function marketDeclareForSale(uint256 tokenId, uint256 minPriceInWei) 
            external returns (bool){
        require (_exists(tokenId));
        require (msg.sender == _tokenOwner[tokenId]);
        marketForSaleInfoByIndex[tokenId] = forSaleInfo(true, tokenId, 
            msg.sender, minPriceInWei, address(0));
        emit ForSaleDeclared(tokenId, msg.sender, minPriceInWei, address(0));
        return true;
    }
    
    // Let anyone interested know that the owner put a token up for sale. 
    // Only the address _to can obtain it by sending an amount of wei equal 
    // to or larger than _minPriceInWei.
    // Only token owner can use this function.

    function marketDeclareForSaleToAddress(uint256 tokenId, uint256 
            minPriceInWei, address to) external returns(bool){
        require (_exists(tokenId));
        require (msg.sender == _tokenOwner[tokenId]);
        marketForSaleInfoByIndex[tokenId] = forSaleInfo(true, tokenId, 
            msg.sender, minPriceInWei, to);
        emit ForSaleDeclared(tokenId, msg.sender, minPriceInWei, to);
        return true;
    }

    // Owner no longer wants token for sale, or token has changed owner, 
    // so previously posted for sale is no longer valid.
    // Only token owner can use this function.

    function marketWithdrawForSale(uint256 tokenId) public returns(bool){
        require (_exists(tokenId));
        require(msg.sender == _tokenOwner[tokenId]);
        marketForSaleInfoByIndex[tokenId] = forSaleInfo(false, tokenId, 
            address(0), 0, address(0));
        emit ForSaleWithdrawn(tokenId, msg.sender);
        return true;
    }
    
    // I'll take it. Must send at least as many wei as minValue in 
    // forSale structure.

    function marketBuyForSale(uint256 tokenId) payable external returns(bool){
        require (_exists(tokenId));
        forSaleInfo storage existingForSale = marketForSaleInfoByIndex[tokenId];
        require(existingForSale.isForSale);
        require(existingForSale.onlySellTo == address(0) || 
            existingForSale.onlySellTo == msg.sender);
        require(msg.value >= existingForSale.minValue);
        address seller = _tokenOwner[tokenId];
        require(existingForSale.seller == seller);
        _transferFrom(seller, msg.sender, tokenId);
        // must withdrawal for sale after transfer to make sure msg.sender
        //  is the current owner.
        marketWithdrawForSale(tokenId);
        // clear bid of new owner, if it exists. 
        if (marketBidInfoByIndex[tokenId].bidder == msg.sender){
            _clearNewOwnerBid(msg.sender, tokenId);
        }
        marketPendingWithdrawals[seller] = marketPendingWithdrawals[seller].add(msg.value);
        emit ForSaleBought(tokenId, msg.value, seller, msg.sender);
        return true;
    }
    
    // Potential buyer puts up money for a token.

    function marketDeclareBid(uint256 tokenId) payable external returns(bool){
        require (_exists(tokenId));
        require (_tokenOwner[tokenId] != msg.sender);
        require (msg.value > 0);
        bidInfo storage existingBid = marketBidInfoByIndex[tokenId];
        // Keep only the highest bid.
        require (msg.value > existingBid.value);
        if (existingBid.value > 0){             
            marketPendingWithdrawals[existingBid.bidder] = 
            marketPendingWithdrawals[existingBid.bidder].add(existingBid.value);
        }
        marketBidInfoByIndex[tokenId] = bidInfo(true, tokenId, 
            msg.sender, msg.value);
        emit BidDeclared(tokenId, msg.value, msg.sender);
        return true;
    }
    
    // Potential buyer changes mind and withdrawals bid.

    function marketWithdrawBid(uint256 tokenId) external returns(bool){
        require (_exists(tokenId));
        require (_tokenOwner[tokenId] != msg.sender); 
        bidInfo storage existingBid = marketBidInfoByIndex[tokenId];
        require (existingBid.hasBid);
        require (existingBid.bidder == msg.sender);
        uint256 amount = existingBid.value;
        // Refund
        marketPendingWithdrawals[existingBid.bidder] =
            marketPendingWithdrawals[existingBid.bidder].add(amount);
        marketBidInfoByIndex[tokenId] = bidInfo(false, tokenId, address(0), 0);
        emit BidWithdrawn(tokenId, amount, msg.sender);
        return true;
    }
    
    // Owner accepts bid, and money and token change hands. All money in wei.
    // Only token owner can use this function.

    function marketAcceptBid(uint256 tokenId, uint256 minPrice) 
            external returns(bool){
        require (_exists(tokenId));
        address seller = _tokenOwner[tokenId];
        require (seller == msg.sender);
        bidInfo storage existingBid = marketBidInfoByIndex[tokenId];
        require (existingBid.hasBid);
        require (existingBid.value >= minPrice);
        address buyer = existingBid.bidder;
        // Remove for sale while msg.sender still owner or approved.
        marketWithdrawForSale(tokenId);
        _transferFrom (seller, buyer, tokenId);
        uint256 amount = existingBid.value;
        // Remove bid.
        marketBidInfoByIndex[tokenId] = bidInfo(false, tokenId, address(0),0);
        marketPendingWithdrawals[seller] = marketPendingWithdrawals[seller].add(amount);
        emit BidAccepted(tokenId, amount, seller, buyer);
        return true;
    }
    
    // Retrieve money to successful sale, failed bid, withdrawn bid, etc.
    //  All in wei. Note that refunds, income, etc. are NOT automatically
    // deposited in the user's address. The user must withdraw the funds.

    function marketWithdrawWei() external returns(bool) {
       uint256 amount = marketPendingWithdrawals[msg.sender];
       require (amount > 0);
       marketPendingWithdrawals[msg.sender] = 0;
       msg.sender.transfer(amount);
       return true;
    } 

    // Clears bid when become owner changes via forSaleBuy or transferFrom.
    
    function _clearNewOwnerBid(address to, uint256 tokenId) internal {

        uint256 amount = marketBidInfoByIndex[tokenId].value;
        marketBidInfoByIndex[tokenId] = bidInfo(false, tokenId, 
            address(0), 0);
        marketPendingWithdrawals[to] = marketPendingWithdrawals[to].add(amount);
        emit BidWithdrawn(tokenId, amount, to);

      
    }
    
    
    //END MARKET
    
    

}