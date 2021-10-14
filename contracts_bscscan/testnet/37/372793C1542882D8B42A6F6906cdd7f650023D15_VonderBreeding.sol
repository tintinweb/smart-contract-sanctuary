/**
 *Submitted for verification at BscScan.com on 2021-10-13
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-10
*/

// SPDX-License-Identifier: MIT
            
pragma solidity ^0.5.12;

contract Ownable{
   
    address payable internal _owner;
      
    modifier onlyOwner(){
      require(msg.sender == _owner, 
      "You need to be owner of the contract in order to access this functionality!");
      _;
    }
    
    constructor() public{ 
      _owner = msg.sender;
    }
}      



/** 
 *  SourceUnit: /Users/dr.lee/Downloads/Crypto-VonderNFTies-master/contracts/CryptoVonderNFTies.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.5.12;

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




/** 
 *  SourceUnit: /Users/dr.lee/Downloads/Crypto-VonderNFTies-master/contracts/CryptoVonderNFTies.sol
*/
            
pragma solidity ^0.5.12;

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}



/** 
 *  SourceUnit: /Users/dr.lee/Downloads/Crypto-VonderNFTies-master/contracts/CryptoVonderNFTies.sol
*/
            
pragma solidity ^0.5.0;
/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
    /**
     * @dev Emitted when `tokenId` token is transfered from `from` to `to`.
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

    /*
     * @dev Returns the total number of tokens in circulation.
     */
    function totalSupply() external view returns (uint256 total);

    /*
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory tokenName);

    /*
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory tokenSymbol);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transfer(address to, uint256 tokenId) external;


    function approve(address _approved, uint256 _tokenId) external;

    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);


    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external;


    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;


    function transferFrom(address _from, address _to, uint256 _tokenId) external;
}




/** 
 *  SourceUnit: /Users/dr.lee/Downloads/Crypto-VonderNFTies-master/contracts/CryptoVonderNFTies.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.5.12;

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



/** 
 *  SourceUnit: /Users/dr.lee/Downloads/Crypto-VonderNFTies-master/contracts/CryptoVonderNFTies.sol
*/
            
pragma solidity ^0.5.12;

////import "./Ownable.sol";

contract Destroyable is Ownable{

    function close() public onlyOwner {
        selfdestruct(_owner);
    }
}

/** 
 *  SourceUnit: /Users/dr.lee/Downloads/Crypto-VonderNFTies-master/contracts/CryptoVonderNFTies.sol
*/

// pragma solidity ^0.5.12;

// contract ERC721Burnable is ERC721 {
//   function burn(uint256 tokenId)
//     public
//   {
//     require(_isApprovedOrOwner(msg.sender, tokenId));
//     _burn(ownerOf(tokenId), tokenId);
//   }
// }


// pragma solidity ^0.5.12;

// /**
//  * @title ERC721 Burnable Token
//  * @dev ERC721 Token that can be irreversibly burned (destroyed).
//  */
// abstract contract ERC721Burnable is Context, ERC721 {
//     /**
//      * @dev Burns `tokenId`. See {ERC721-_burn}.
//      *
//      * Requirements:
//      *
//      * - The caller must own `tokenId` or be an approved operator.
//      */
//     function burn(uint256 tokenId) public virtual {
//         //solhint-disable-next-line max-line-length
//         require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
//         _burn(tokenId);
//     }
// }





















pragma solidity ^0.5.12;



contract VonderBreeding is Ownable, Destroyable, IERC165, IERC721 {

    using SafeMath for uint256;

    uint256 public constant maxGen0VonderNFTs = 10;//allow a maximum of 10 Gen0 VonderNFTs
    uint256 public gen0Counter = 0;

    bytes4 internal constant _ERC721Checksum = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    //checksum used to determine if a receiving contract is able to handle ERC721 tokens
    bytes4 private constant _InterfaceIdERC721 = 0x80ac58cd;
    //checksum of function headers that are required in standard interface
    bytes4 private constant _InterfaceIdERC165 = 0x01ffc9a7;
    //checksum of function headers that are required in standard interface

    string private _name;
    string private _symbol;

    struct VonderNFT {
        uint256 genes;
        uint64 birthTime;
        uint32 mumId;
        uint32 dadId;
        uint16 generation;
    }

    VonderNFT[] VonderNFTies;

    mapping(uint256 => address) public VonderNFTOwner;
    mapping(address => uint256) ownsNumberOfTokens;
    mapping(uint256 => address) public approvalOneVonderNFT;//which VonderNFT is approved to be transfered
                                                       //by an address other than the owner
    mapping(address => mapping (address => bool)) private _operatorApprovals;
    //approval to handle all tokens of an address by another
    //_operatorApprovals[owneraddress][operatoraddress] = true/false;
    
    mapping(uint256 => address) internal tokenOwner;
    //ERC721 events are not defined here as they are inherited from IERC721
    event Birth(address owner, uint256 VonderNFTId, uint256 mumId, uint256 dadId, uint256 genes);

    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _createVonderNFT(0, 0, 0, uint256(-1), address(0));
        //VonderNFT 0 doesn't do anything, but it exists in the mappings and arrays to avoid issues in the market place
    }

    function getContractOwner() external view returns (address contractowner) {
        return _owner;
    }

    function breed(uint256 _dadId, uint256 _mumId) external returns (uint256){
        require(VonderNFTOwner[_dadId] == msg.sender && VonderNFTOwner[_mumId] == msg.sender, 
        "You can't breed what you don't own");
        
        (uint256 _dadDna,,,, uint256 _dadGeneration) = getVonderNFT(_dadId);//discarding redundant data here
        (uint256 _mumDna,,,, uint256 _mumGeneration) = getVonderNFT(_mumId);//discarding redundant data here
        uint256 _newDna = _mixDna(
            _dadDna, 
            _mumDna,
            uint8(now % 255),//This will return a number 0-255. e.g. 10111000
            uint8(now % 1),//seventeenth digit
            uint8(now % 7),//number to select random pair.
            uint8((now % 89) + 10)//value of random pair, making sure there's no leading '0'.
            );
        uint256 _newGeneration;

        if (_dadGeneration <= _mumGeneration) {
            _newGeneration = _dadGeneration;
        } else {
            _newGeneration = _mumGeneration;
        }
        _newGeneration = SafeMath.add(_newGeneration, 1);
        return _createVonderNFT(_mumId, _dadId, _newGeneration, _newDna, msg.sender);
    }
    
    

    function supportsInterface(bytes4 _interfaceId) external view returns (bool) {
        return (_interfaceId == _InterfaceIdERC721 || _interfaceId == _InterfaceIdERC165);
    }

    function createVonderNFTGen0(uint256 genes) public onlyOwner returns (uint256) {
        require(gen0Counter < maxGen0VonderNFTs, "Maximum number of VonderNFTs is reached. No new VonderNFTs allowed!");
        gen0Counter = SafeMath.add(gen0Counter, 1);
        return _createVonderNFT(0, 0, 0, genes, msg.sender);
    }

    function _createVonderNFT(
        uint256 _mumId,
        uint256 _dadId,
        uint256 _generation,
        uint256 _genes,
        address _owner
    ) internal returns (uint256) {
        VonderNFT memory _VonderNFT = VonderNFT({
            genes: _genes,
            birthTime: uint64(now),
            mumId: uint32(_mumId),  //easier to input 256 and later convert to 32.
            dadId: uint32(_dadId),
            generation: uint16(_generation)
        });
        VonderNFTies.push(_VonderNFT);
        uint256 newVonderNFTId = SafeMath.sub(VonderNFTies.length, 1);//want to start with zero.
        _transfer(address(0), _owner, newVonderNFTId);//transfer from nowhere. Creation event.
        emit Birth(_owner, newVonderNFTId, _mumId, _dadId, _genes);
        return newVonderNFTId;
    }
    
    function burn(uint256 _tokenId) public {
        tokenOwner[_tokenId] = address(0);
        //super.burn(VonderNFTOwner(_tokenId), _tokenId);
    }
    
    function _burn(address to, uint256 tokenId) external{
        require(to != address(0), "Use the burn function to burn tokens!");
        require(VonderNFTOwner[tokenId] == msg.sender);
        _transfer(msg.sender, to, tokenId);
    }
    //  function _burn(uint256 tokenId) internal virtual {
    //     address owner = ERC721.ownerOf(tokenId);

    //     _beforeTokenTransfer(owner, address(0), tokenId);

    //     // Clear approvals
    //     _approve(address(0), tokenId);

    //     _balances[owner] -= 1;
    //     delete _owners[tokenId];

    //     emit Transfer(owner, address(0), tokenId);
    // }
    
    function getVonderNFT(uint256 tokenId) public view returns (
        uint256 genes,
        uint256 birthTime,
        uint256 mumId,
        uint256 dadId,
        uint256 generation) //code looks cleaner when the params appear here vs. in the return statement.
        {
            require(tokenId < VonderNFTies.length, "Token ID doesn't exist.");
            VonderNFT storage VonderNFT = VonderNFTies[tokenId];//saves space over using memory, which would make a copy
            
            genes = VonderNFT.genes;
            birthTime = uint256(VonderNFT.birthTime);
            mumId = uint256(VonderNFT.mumId);
            dadId = uint256(VonderNFT.dadId);
            generation = uint256(VonderNFT.generation);
    }

    function getAllVonderNFTsOfOwner(address owner) external view returns(uint256[] memory) {
        uint256[] memory allVonderNFTsOfOwner = new uint[](ownsNumberOfTokens[owner]);
        uint256 j = 0;
        for (uint256 i = 0; i < VonderNFTies.length; i++) {
            if (VonderNFTOwner[i] == owner) {
                allVonderNFTsOfOwner[j] = i;
                j = SafeMath.add(j, 1);
            }
        }
        return allVonderNFTsOfOwner;
    }

    function balanceOf(address owner) external view returns (uint256 balance) {
        return ownsNumberOfTokens[owner];
    }

    function totalSupply() external view returns (uint256 total) {
        return VonderNFTies.length;
    }

    function name() external view returns (string memory tokenName){
        return _name;
    }

    function symbol() external view returns (string memory tokenSymbol){
        return _symbol;
    }

    function ownerOf(uint256 tokenId) external view returns (address owner) {
        require(tokenId < VonderNFTies.length, "Token ID doesn't exist.");
        return VonderNFTOwner[tokenId];
    }

    function transfer(address to, uint256 tokenId) external {
        require(to != address(0), "Use the burn function to burn tokens!");
        require(to != address(this), "Wrong address, try again!");
        require(VonderNFTOwner[tokenId] == msg.sender);
        _transfer(msg.sender, to, tokenId);
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        require(_to != address(this));
        ownsNumberOfTokens[_to] = SafeMath.add(ownsNumberOfTokens[_to], 1);
        VonderNFTOwner[_tokenId] = _to;
        
        if (_from != address(0)) {
            ownsNumberOfTokens[_from] = SafeMath.sub(ownsNumberOfTokens[_from], 1);
            delete approvalOneVonderNFT[_tokenId];//when owner changes, approval must be removed.
        }

        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external {
        require(VonderNFTOwner[_tokenId] == msg.sender || _operatorApprovals[VonderNFTOwner[_tokenId]][msg.sender] == true, 
        "You are not authorized to access this function.");
        approvalOneVonderNFT[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != msg.sender);
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) external view returns (address) {
        require(_tokenId < VonderNFTies.length, "Token doesn't exist");
        return approvalOneVonderNFT[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    function _safeTransfer(address _from, address _to, uint256 _tokenId, bytes memory _data) internal {
        require(_checkERC721Support(_from, _to, _tokenId, _data));
        _transfer(_from, _to, _tokenId);
    }
    
    function _checkERC721Support(address _from, address _to, uint256 _tokenId, bytes memory _data) 
            internal returns(bool) {
        if(!_isContract(_to)) {
            return true;
        }
        bytes4 returnData = IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
        //Call onERC721Received in the _to contract
        return returnData == _ERC721Checksum;
        //Check return value
    }

    function _isContract(address _to) internal view returns (bool) {
        uint32 size;
        assembly{
            size := extcodesize(_to)
        }
        return size > 0;
        //check if code size > 0; wallets have 0 size.
    }

    function _isOwnerOrApproved(address _from, address _to, uint256 _tokenId) internal view returns (bool) {
        require(_from == msg.sender || 
                approvalOneVonderNFT[_tokenId] == msg.sender || 
                _operatorApprovals[_from][msg.sender], 
                "You are not authorized to use this function");
        require(VonderNFTOwner[_tokenId] == _from, "Owner incorrect");
        require(_to != address(0), "Error: Operation would delete this token permanently");
        require(_tokenId < VonderNFTies.length, "Token doesn't exist");
        return true;
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external {
        _isOwnerOrApproved(_from, _to, _tokenId);
        _safeTransfer(_from, _to, _tokenId, data);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        _isOwnerOrApproved(_from, _to, _tokenId);
        _safeTransfer(_from, _to, _tokenId, "");
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        _isOwnerOrApproved(_from, _to, _tokenId);
        _transfer(_from, _to, _tokenId);
    }

    function _mixDna(
        uint256 _dadDna, 
        uint256 _mumDna,
        uint8 random,
        uint8 randomSeventeenthDigit,
        uint8 randomPair,
        uint8 randomNumberForRandomPair
        ) internal pure returns (uint256){
        
        uint256[9] memory geneArray;
        uint256 i;
        uint256 counter = 7; // start on the right end

        //DNA example: 11 22 33 44 55 66 77 88 9

        if(randomSeventeenthDigit == 0){
            geneArray[8] = uint8(_mumDna % 10); //this takes the 17th gene from mum.
        } else {
            geneArray[8] = uint8(_dadDna % 10); //this takes the 17th gene from dad.
        }

        _mumDna = SafeMath.div(_mumDna, 10); // division by 10 removes the last digit
        _dadDna = SafeMath.div(_dadDna, 10); // division by 10 removes the last digit

        for (i = 1; i <= 128; i=i*2) {                      //1, 2 , 4, 8, 16, 32, 64 ,128
            if(random & i == 0){                            //00000001
                geneArray[counter] = uint8(_mumDna % 100);  //00000010 etc.
            } else {                                        //11001011 &
                geneArray[counter] = uint8(_dadDna % 100);  //00000001 will go through random number bitwise
            }                                               //if(1) - dad gene
            _mumDna = SafeMath.div(_mumDna, 100);           //if(0) - mum gene
            _dadDna = SafeMath.div(_dadDna, 100);           //division by 100 removes last two digits from genes
            if(counter > 0) {
                counter = SafeMath.sub(counter, 1);
            }
        }

        geneArray[randomPair] = randomNumberForRandomPair; //extra randomness for random pair.

        uint256 newGene = 0;

        //geneArray example: [11, 22, 33, 44, 55, 66, 77, 88, 9]

        for (i = 0; i < 8; i++) {                           //8 is number of pairs in array
            newGene = SafeMath.mul(newGene, 100);           //adds two digits to newGene; no digits the first time
            newGene = SafeMath.add(newGene, geneArray[i]);  //adds a pair of genes
        }
        newGene = SafeMath.mul(newGene, 10);                //add seventeenth digit
        newGene = SafeMath.add(newGene, geneArray[8]);
        return newGene;
    }
}