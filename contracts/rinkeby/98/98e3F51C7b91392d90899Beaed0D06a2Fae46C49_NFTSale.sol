// SPDX-License-Identifier: MIT

// Create an ERC721 Token with the following requirements

// 1. user can only buy tokens when the sale is started
// 2. the sale should be ended within 365 days
// 3. the owner can set base URI
// 4. the owner can set the price of NFT
// 5. NFT minting hard limit is 250

 
    // ************************************************** // 

pragma solidity ^0.8.4;

import "./ERC721.sol";


contract NFTSale is ERC721 { 
    
    uint256 public saleStartTime;
    uint256 private salePeriod;
    uint256 private saleEndTime;
    uint256 private NFTPrice;
    uint256 private NFTMaxSupply;
    uint256 internal tokenID;
    uint256 public currentSupply;
    uint256 public fundRaised;
    uint256 public lastTokenID;
    
     // ************************************************** // 
    
    constructor() {
        
        saleStartTime = block.timestamp + 60;
        salePeriod = 365 days;       /*  365 days --- consider 180 second for sake of practice */
        saleEndTime = saleStartTime + salePeriod ;
        NFTMaxSupply = 25;       /*  25 NFT --- consider 5NFT for practice only*/
        tokenID = 0;
        lastTokenID = tokenID;
        currentSupply = 0;
        baseURI_ =  "https://gateway.pinata.cloud/ipfs/QmVdF3B1JHmJY7CpmCj8QTXzcWwaKByEJMFm8xb8i7Nbj3/";  
        mintNFTatDeployement(msg.sender, 5);
        setNFTPrice(1); /* price is equal to ETH 0.01*/
    }

    fallback() external payable {}
    receive() external payable {}
    
    modifier isSaleStart(){
        require(saleStartTime < block.timestamp, "TheToken: sale yet to start");
        require(NFTPrice > 0,"TheToken: NFT price is not yet set");
        require(bytes(baseURI_).length > 0,"TheToken: baseURI need to be decleared");
        _;
    }
    
     modifier isSaleEnd(){
        require(block.timestamp < saleEndTime, "TheToken: sale ended");
        _;
    }
    
    modifier maxSupply(){
        require(currentSupply < NFTMaxSupply ,"Max Supply achived");
        _;
    }   
   
   
   
   // ************************************************** // 
   
   function setNFTPrice(uint256 _NFTPrice) public onlyOwner() {
       NFTPrice = _NFTPrice * 10**16;       /*     1 ether   */
    }
   
   function getNFTPrice() public view returns(uint256) {
       return NFTPrice;
    }
   
   
   
    // ************************************************** // 
   
   function setBaseURI(string memory BaseURI) public onlyOwner() {
       baseURI_ = BaseURI;          /*     https://my-json-server.typicode.com/asimro/NFTdata/tokens/    */
    }
   
   
   
    // ************************************************** // 
        
    function buyNFT(address to) public payable isSaleStart isSaleEnd maxSupply returns(uint256 totalFunds){
        require(msg.value == NFTPrice && msg.sender != address(0),"TheToken: unrequired value");
        
        payable(address(this)).transfer(msg.value);
        fundRaised = fundRaised + msg.value;
        
        tokenID += 1;
        lastTokenID = tokenID;
        currentSupply +=1;
        _mint(to, tokenID);
        return fundRaised;
    }

    function buyNFTs(address to, uint256 _countNfts) public payable isSaleStart isSaleEnd maxSupply returns(uint256 totalFunds){
        uint NFTsPrice = NFTPrice * _countNfts;
        require(msg.value == NFTsPrice && msg.sender != address(0),"TheToken: unrequired value");
        
        payable(address(this)).transfer(msg.value);
        fundRaised = fundRaised + msg.value;
        
        for(uint i = 0; i < _countNfts; i++ ){
        tokenID += 1;
        lastTokenID = tokenID;
        currentSupply +=1;
        _mint(to, tokenID);
        }
        return fundRaised;
    }

    function mintNFTatDeployement(address to, uint256 _countNfts) internal onlyOwner {
        for(uint i = 0; i < _countNfts; i++ ){
        tokenID += 1;
        lastTokenID = tokenID;
        currentSupply +=1;
        _mint(to, tokenID);
         }
    }

    // ************************************************** // 


    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    

    function killingContract()external payable onlyOwner() returns(bool){
        require(block.timestamp > saleEndTime,"TheToken: sale in progress");
        
        emit Transfer(address(this), owner(), fundRaised);    
        selfdestruct(payable(owner()));
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./Strings.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./ERC165.sol";


contract ERC721 is ERC165, IERC721, Ownable { 
    
    using Strings for uint256;
    using Address for address;
    
    string private _name;
    string private _symbol;
    string internal baseURI_;
    
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _owners;
    
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
 
    
    
    // ************************************************** // 
    
    constructor () {
        _name = "Champions";
        _symbol = "CHM";
    }
    
   
    
    // ************************************************** // 
    
    modifier isExists(uint256 tokenID){
        require(_owners[tokenID] != address(0),"ERC721: tokenID does not exists");
        _;
    }
    
    modifier isAuthorizer(address operator, uint256 tokenID){
        address owner_ = _owners[tokenID];
        
        require(operator != address(0),"ERC721: operator is zero address"); 
        require(operator == owner_ || operator == _tokenApprovals[tokenID] || _operatorApprovals[owner_][operator]
            ,"ERC721: unauthorized caller");  
        _;
    }
    
    
    // ************************************************** //
     
    function tokenURI(uint256 tokenID)external view returns(string memory){
      return  _tokenURI(tokenID) ;
    } 
    
    
   function _tokenURI(uint256 tokenID)internal isExists(tokenID) view returns(string memory){
        string memory baseURI  = baseURI_;
        string memory json = ".json";
        string memory baseURI_ID = string(abi.encodePacked(baseURI, tokenID.toString()));
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI_ID, json)) : "";
    } 
     
    
    // ************************************************** // 
    
    function name()public view returns(string memory){
        return _name;
    }
    
    function symbol()public view returns(string memory){
        return _symbol;
    }
    
    function contractBalance()public view returns(uint256){
        return address(this).balance;
    }
    
    
    
    
    // ************************************************** // 
    
    function balanceOf(address owner) external view virtual override returns(uint256){
        require(owner != address(0),"ERC721: checking balance for zero address");
        return _balances[owner];
    }
    
    function ownerOf(uint256 tokenID) external view isExists(tokenID) virtual override returns(address){
        address owner = _owners[tokenID];
        require(owner != address(0),"ERC721: checking tokenID for zero address");
        return owner; 
    }
    
    
    
     // ************************************************** // 
     
    function approve(address operator, uint256 tokenID) external
        isExists(tokenID)
        isAuthorizer(msg.sender, tokenID)
        virtual override {
            require(msg.sender != address(0),"ERC721: caller is zero address");
            _approve(operator, tokenID);
    }
    
    function _approve(address operator, uint256 tokenID) internal virtual {
       _tokenApprovals[tokenID] = operator;
       emit Approval(_owners[tokenID], operator, tokenID);
    }
    
    function getApproved(uint256 tokenID) external view
        isExists(tokenID)
        override returns(address operator) {
            return _tokenApprovals[tokenID];
    }
    
    
    
    // ************************************************** // 
    
    function setApprovalForAll(address operator, bool approved) external override {
        require(msg.sender != operator, "ERC721: caller to apporver");
        
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll (msg.sender, operator, approved);
    }
    
    function isApprovedForAll(address owner, address operator)public view override returns(bool){
        return _operatorApprovals[owner][operator];
    }
    
    function unsetApprovalForAll(address operator, bool unApproved) external {
        require(msg.sender != operator, "ERC721: caller to apporver");
        
        _operatorApprovals[msg.sender][operator] = unApproved;
        emit ApprovalForAll (msg.sender, operator, unApproved);
    }
    
    
    
     // ************************************************** // 
    
     function transferFrom(
        address from,
        address to,
        uint256 tokenID
        )external override
        {
           _transferFrom(from, to, tokenID); 
        }
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenID
        )external override
        {
           safeTransferFrom(from, to, tokenID,""); 
        }
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenID,
        bytes memory data
        )public override 
        {
           _transferFrom(from, to, tokenID); 
           require(_checkOnERC721Received(from, to, tokenID, data), "ERC721: transfer to non ERC721Receiver implementer");
        }
    
    
    function _transferFrom(
        address from,
        address to,
        uint256 tokenID
        )internal virtual
        isAuthorizer (msg.sender, tokenID) 
        isExists(tokenID) {
           
           require(to != address(0),"receipient is not a valid address");
           _approve(address(0),tokenID);
           
           _balances[from] -= 1;
           _balances[to] += 1;
           
           _owners[tokenID] = to;
           emit Transfer(from, to, tokenID);
        }
        
        
        
        
    // ************************************************** //     
        
     function _mint(address to, uint256 tokenID) internal virtual {
         
        require(to != address(0), "ERC721: mint to the zero address");
        require(!(_owners[tokenID] != address(0)), "ERC721: token already minted");  /*!(_owners[tokenID] != address(0))*/
        require(_checkOnERC721Received(address(0), to, tokenID, ""),"ERC721: transfer to non ERC721Receiver implementer");

            _balances[to] += 1;
            _owners[tokenID] = to;

        emit Transfer(address(0), to, tokenID);
        }
    
    
    
    // ************************************************** //  
    
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
    
        
        
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}



    //  **************************************************************************************************   //
    
abstract contract ERC165 is IERC165 {
    
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Ownable{
    
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(msg.sender);
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
       function owner() public view virtual returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

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

pragma solidity ^0.8.4;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenID,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC721 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenID);
    event Approval(address indexed owner, address indexed operator, uint256 indexed tokenID);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
 
 
 
    function balanceOf(address owner)external view returns(uint256 balance);
    function ownerOf(uint256 tokenID)external view returns(address owner);
    
    
    
    function approve(address operator, uint256 tokenID)external;
    function getApproved(uint256 tokenID)external view returns(address operator);
    
    
    
    function setApprovalForAll(address operator,bool approved) external;
    function isApprovedForAll(address owner,address operator)external view returns(bool);

    
    
    
    function transferFrom(
        address from,
        address to,
        uint256 tokenID
        )external;
        
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenID
        ) external;
        
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenID,
        bytes calldata data
        ) external;

}