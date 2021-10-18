/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

pragma solidity 0.7.6;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (C) 2021 CryptoDogsClub
 * https://www.cryptodogsclub.com
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                       @@@@@@                @@@@@@@                            
                  @@@@@//////@@@           @@///////@@@@                        
                @@...../////////@@@@@@@@@@@/////////[email protected]@                      
                  @@@@@  @@////////////////////@@   @@@@                        
                         @@//@@@@@//////@@@@@//@@                               
                         @@//  -  //////  -  //@@                               
                         @@////////////////////@@                               
                       @@///////@@@@@@@@@@@//////@@@                            
                       @@/////////@@@@@@/////////@@@                            
                    @@@/////////////////////////////@@                          
                    @@@    ////////////////////     @@                          
                       @@    @@@           @@    @@@      @@@@@                 
                       @@       @@@@@@@@@@@      @@@      @@///@@               
                         @@@@                @@@@           @@@//@@             
                             @@@@@@@@@@@@@@@@@@             @@@////@@           
                                @@/////////////@@              @@//@@           
                             @@@/////////////////@@@           @@//@@           
                             @@@////////////////////@@         @@//@@           
                           @@/////////////////////////@@       @@//@@          
*/
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity 0.7.6;

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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

pragma solidity 0.7.6;

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }



    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

pragma solidity 0.7.6;
pragma abicoder v2;
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

interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface ERC721TokenReceiver {
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}

interface NFTReferral {
    /**
     * @dev Record referral.
     */
    function recordReferral(address user, address referrer) external;
    
    /**
     * @dev Record referral commission.
     */
    function recordReferralCount(address referrer, uint256 numberOfNfts) external;

    /**
     * @dev Get the referrer address that referred the user.
     */
    function getReferrer(address user) external view returns (address);
}

library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }
}

contract CryptoDogsNFTDrop is IERC721{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    event Mint(uint256 indexed index, address indexed minter);

    event DoggyOffered(
        uint256 indexed doggyIndex,
        uint256 minValue,
        address indexed toAddress
    );
    
    event DoggyBidEntered(
        uint256 indexed doggyIndex,
        uint256 value,
        address indexed fromAddress
    );
    event DoggyBidWithdrawn(
        uint256 indexed doggyIndex,
        uint256 value,
        address indexed fromAddress
    );
    event DoggyBought(
        uint256 indexed doggyIndex,
        uint256 saleFee,
        address indexed fromAddress,
        address indexed toAddress
    );
    event DoggyNoLongerForSale(uint256 indexed doggyIndex);
    /**
     * Event emitted when the public sale begins.
     */
    event DropBegins();
    
    // Recover NFT tokens sent by accident
    event NonFungibleTokenRecovery(address indexed token, uint256 indexed tokenId);
    
    // Recover ERC20 tokens sent by accident
    event TokenRecovery(address indexed token, uint256 amount);
    
    // CryptoDogs referral contract address.	
    	
    NFTReferral public tokenReferral;
    
    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    uint256 public constant TOKEN_LIMIT = 100000;

    uint16 public constant MAXIMUM_COMMISSION_RATE = 10;
    
    mapping(bytes4 => bool) internal supportedInterfaces;

    mapping(uint256 => address) internal idToOwner;

    mapping(uint256 => address) internal idToApproval;

    mapping(address => mapping(address => bool)) internal ownerToOperators;
    
    mapping(address => uint256[]) internal ownerToIds;

    mapping(uint256 => uint256) internal idToOwnerIndex;

    string internal nftName = "Crypto Dogs Club AirDrop NFTs";
    string internal nftSymbol = "DOGGO";

    // You can use this hash to verify the image file containing all the doggys
    string public imageHash;

    uint256 internal numTokens = 0;
    uint256 internal numSales = 0;

    address payable internal deployer;
    address payable internal developer;

    bool public publicDrop = false;
    bool public hasEnded = false;
    uint256 public marketFeeRate = 25;
    uint256 public totalMarketFee;
    uint256 public startTime;
    uint256 public endTime;
    
    //// Random index assignment
    uint256 internal nonce = 0;
    uint256[TOKEN_LIMIT] internal indices;

    //// Market
    bool public marketPaused;
    bool public contractSealed;
    mapping(bytes32 => bool) public cancelledOffers;
    
    modifier onlyDeployer() {
        require(msg.sender == deployer, "Only deployer.");
        _;
    }

    bool private reentrancyLock = false;

    /* Prevent a contract function from being reentrant-called. */
    modifier reentrancyGuard() {
        if (reentrancyLock) {
            revert();
        }
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == msg.sender ||
                ownerToOperators[tokenOwner][msg.sender],
            "Cannot operate."
        );
        _;
    }

    modifier canTransfer(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == msg.sender ||
                idToApproval[_tokenId] == msg.sender ||
                ownerToOperators[tokenOwner][msg.sender],
            "Cannot transfer."
        );
        _;
    }

    modifier validNFToken(uint256 _tokenId) {
        require(idToOwner[_tokenId] != address(0), "Invalid token.");
        _;
    }

    constructor(address payable _developer, string memory _imageHash, uint256 _startTime, uint256 _endTime) {
        require(
            block.timestamp < _startTime,
            "Invalid startTime."
        );
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        supportedInterfaces[0x780e9d63] = true; // ERC721 Enumerable
        supportedInterfaces[0x5b5e139f] = true; // ERC721 Metadata
        deployer = msg.sender;
        developer = _developer;
        imageHash = _imageHash;
        startTime = _startTime;
        endTime = _endTime;
    }

    function startAirdrop() external onlyDeployer {
        require(!publicDrop);
        publicDrop = true;
        emit DropBegins();
    }

    function pauseMarket(bool _paused) external onlyDeployer {
        require(!contractSealed, "Contract sealed.");
        marketPaused = _paused;
    }
    
    function sealContract() external onlyDeployer {
        contractSealed = true;
    }
    
    function stopAirdrop() external onlyDeployer{
       publicDrop = false;
       hasEnded = true;
       endTime = block.timestamp;
       emit DropBegins();
    }
    		
    // Update the token referral contract address by the owner	
    function setNFTReferral(NFTReferral _tokenReferral) public onlyDeployer {	
        tokenReferral = _tokenReferral;	
    }
    //////////////////////////
    //// ERC 721 and 165  ////
    //////////////////////////

    function isContract(address _addr)
        internal
        view
        returns (bool addressCheck)
    {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        } // solhint-disable-line
        addressCheck = size > 0;
    }

    function supportsInterface(bytes4 _interfaceID)
        external
        view
        override
        returns (bool)
    {
        return supportedInterfaces[_interfaceID];
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external override {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external override {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external override canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, "Wrong from address.");
        require(_to != address(0), "Cannot send to 0x0.");
        _transfer(_to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId)
        external
        override
        canOperate(_tokenId)
        validNFToken(_tokenId)
    {
        address tokenOwner = idToOwner[_tokenId];
        require(_approved != tokenOwner);
        idToApproval[_tokenId] = _approved;
        emit Approval(tokenOwner, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved)
        external
        override
    {
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function balanceOf(address _owner)
        external
        view
        override
        returns (uint256)
    {
        require(_owner != address(0));
        return _getOwnerNFTCount(_owner);
    }

    function ownerOf(uint256 _tokenId)
        public
        view
        override
        returns (address _owner)
    {
        require(idToOwner[_tokenId] != address(0));
        _owner = idToOwner[_tokenId];
    }

    function getApproved(uint256 _tokenId)
        external
        view
        override
        validNFToken(_tokenId)
        returns (address)
    {
        return idToApproval[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        override
        returns (bool)
    {
        return ownerToOperators[_owner][_operator];
    }

    function _transfer(address _to, uint256 _tokenId) internal {
        address from = idToOwner[_tokenId];
        _clearApproval(_tokenId);

        _removeNFToken(from, _tokenId);
        _addNFToken(_to, _tokenId);

        emit Transfer(from, _to, _tokenId);
    }

    function randomIndex() internal returns (uint256) {
        uint256 totalSize = TOKEN_LIMIT - numTokens;
        uint256 index = uint256(
            keccak256(
                abi.encodePacked(
                    nonce,
                    msg.sender,
                    block.difficulty,
                    block.timestamp
                )
            )
        ) % totalSize;
        uint256 value = 0;
        if (indices[index] != 0) {
            value = indices[index];
        } else {
            value = index;
        }

        // Move last value to selected position
        if (indices[totalSize - 1] == 0) {
            // Array position not initialized, so use position
            indices[index] = totalSize - 1;
        } else {
            // Array position holds a value so use that
            indices[index] = indices[totalSize - 1];
        }
        nonce++;
        // Don't allow a zero index, start counting at 1
        return value.add(1);
    }

    function mintsRemaining() public view returns (uint256) {
        return TOKEN_LIMIT.sub(numSales);
    }

    /**
     * Public Drop minting.
     */
    function claimDrop(address _referrer) external reentrancyGuard {
        require(publicDrop, "Airdrop not started.");
        require(
            totalSupply().add(1) <= TOKEN_LIMIT,
            "Exceeds TOKEN_LIMIT"
        );
        require(endTime >= block.timestamp, "Airdrop is finished.");
        require(
            _getOwnerNFTCount(msg.sender) <1, 
            'CryptoDogs: Airdrop already claimed.'
        );
        uint256 numberOfNfts =1;
        if (numberOfNfts > 0 && address(tokenReferral) != address(0) && _referrer != address(0) && _referrer != msg.sender) {
            tokenReferral.recordReferral(msg.sender, _referrer);
            tokenReferral.recordReferralCount(_referrer, numberOfNfts);
        }
        _mint(msg.sender);
    }
    
    function mintForTeam(uint256 numberOfNfts) external reentrancyGuard onlyDeployer {
        require(numberOfNfts > 0, "numberOfNfts cannot be 0");
        require(
            numberOfNfts <= 100,
            "You can not buy more than 100 NFTs at once"
        );
        require(
            totalSupply().add(numberOfNfts) <= TOKEN_LIMIT,
            "Exceeds TOKEN_LIMIT"
        );
        for (uint256 i = 0; i < numberOfNfts; i++) {
            numSales++;
            _mint(msg.sender);
        }
    }

    function _mint(address _to) internal returns (uint256) {
        require(_to != address(0), "Cannot mint to 0x0.");
        require(numTokens < TOKEN_LIMIT, "Token limit reached.");
        uint256 id = randomIndex();

        numTokens = numTokens + 1;
        _addNFToken(_to, id);

        emit Mint(id, _to);
        emit Transfer(address(0), _to, id);
        return id;
    }

    function _addNFToken(address _to, uint256 _tokenId) internal {
        require(
            idToOwner[_tokenId] == address(0),
            "Cannot add, already owned."
        );
        idToOwner[_tokenId] = _to;

        ownerToIds[_to].push(_tokenId);
        idToOwnerIndex[_tokenId] = ownerToIds[_to].length.sub(1);
    }

    function _removeNFToken(address _from, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == _from, "Incorrect owner.");
        delete idToOwner[_tokenId];

        uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
        uint256 lastTokenIndex = ownerToIds[_from].length.sub(1);

        if (lastTokenIndex != tokenToRemoveIndex) {
            uint256 lastToken = ownerToIds[_from][lastTokenIndex];
            ownerToIds[_from][tokenToRemoveIndex] = lastToken;
            idToOwnerIndex[lastToken] = tokenToRemoveIndex;
        }

        ownerToIds[_from].pop();
    }

    function _getOwnerNFTCount(address _owner) internal view returns (uint256) {
        return ownerToIds[_owner].length;
    }

    function _safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) private canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, "Incorrect owner.");
        require(_to != address(0));

        _transfer(_to, _tokenId);

        if (isContract(_to)) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(
                msg.sender,
                _from,
                _tokenId,
                _data
            );
            require(retval == MAGIC_ON_ERC721_RECEIVED);
        }
    }

    function _safeTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) private validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, "Incorrect owner.");
        require(_to != address(0));

        _transfer(_to, _tokenId);

        if (isContract(_to)) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(
                msg.sender,
                _from,
                _tokenId,
                _data
            );
            require(retval == MAGIC_ON_ERC721_RECEIVED);
        }
    }

    function _clearApproval(uint256 _tokenId) private {
        if (idToApproval[_tokenId] != address(0)) {
            delete idToApproval[_tokenId];
        }
    }

    //// Enumerable

    function totalSupply() public view returns (uint256) {
        return numTokens;
    }

    function tokenByIndex(uint256 index) public pure returns (uint256) {
        require(index >= 0 && index < TOKEN_LIMIT);
        return index + 1;
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        returns (uint256)
    {
        require(_index < ownerToIds[_owner].length);
        return ownerToIds[_owner][_index];
    }
    
    //// Metadata

    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + (temp % 10)));
            temp /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Returns a descriptive name for a collection of NFTokens.
     * @return _name Representing name.
     */
    function name() external view returns (string memory _name) {
        _name = nftName;
    }

    /**
     * @dev Returns an abbreviated name for NFTokens.
     * @return _symbol Representing symbol.
     */
    function symbol() external view returns (string memory _symbol) {
        _symbol = nftSymbol;
    }

    /**
     * @dev A distinct URI (RFC 3986) for a given NFT.
     * @param _tokenId Id for which we want uri.
     * @return _tokenId URI of _tokenId.
     */
    function tokenURI(uint256 _tokenId)
        external
        view
        validNFToken(_tokenId)
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "https://cryptodogsclub.com/api/dogs/",
                    toString(_tokenId)
                )
            );
    }

    //// MARKET

    struct Offer {
        bool isForSale;
        uint256 doggyIndex;
        address seller;
        uint256 minValue; // in BNB
        address onlySellTo; // specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid;
        uint256 doggyIndex;
        address bidder;
        uint256 value;
    }

    // A record of doggys that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping(uint256 => Offer) public doggysOfferedForSale;

    // A record of the highest doggy bid
    mapping(uint256 => Bid) public doggyBids;

    mapping(address => uint256) public pendingWithdrawals;

    modifier onlyTokenOwner(uint256 _tokenId) {
        require(_tokenId < 100000, "doggy number is wrong");
        require(ownerOf(_tokenId) == msg.sender, "Incorrect owner.");
        _;
    }

    function doggyNoLongerForSale(uint256 doggyIndex)
        public
        reentrancyGuard
        onlyTokenOwner(doggyIndex)
    {
        _doggyNoLongerForSale(doggyIndex);
    }

    function _doggyNoLongerForSale(uint256 doggyIndex) private {
        doggysOfferedForSale[doggyIndex] = Offer(
            false,
            doggyIndex,
            msg.sender,
            0,
            address(0)
        );
        emit DoggyNoLongerForSale(doggyIndex);
    }

    function offerDoggyForSale(uint256 doggyIndex, uint256 minSalePriceInWei)
        public
        reentrancyGuard
        onlyTokenOwner(doggyIndex)
    {
        require(marketPaused == false, "Market Paused");
        doggysOfferedForSale[doggyIndex] = Offer(
            true,
            doggyIndex,
            msg.sender,
            minSalePriceInWei,
            address(0)
        );
        emit DoggyOffered(doggyIndex, minSalePriceInWei, address(0));
    }

    function offerDoggyForSaleToAddress(
        uint256 doggyIndex,
        uint256 minSalePriceInWei,
        address toAddress
    ) public reentrancyGuard onlyTokenOwner(doggyIndex) {
        require(marketPaused == false, "Market Paused");
        doggysOfferedForSale[doggyIndex] = Offer(
            true,
            doggyIndex,
            msg.sender,
            minSalePriceInWei,
            toAddress
        );
        emit DoggyOffered(doggyIndex, minSalePriceInWei, toAddress);
    }

    function buyDoggy(uint256 doggyIndex) public payable reentrancyGuard {
        require(marketPaused == false, "Market Paused");
        require(doggyIndex < 100000, "doggy number is wrong");
        Offer memory offer = doggysOfferedForSale[doggyIndex];
        require(offer.isForSale, "doggy not actually for sale");
        require(
            offer.onlySellTo == address(0) || offer.onlySellTo == msg.sender,
            "doggy not supposed to be sold to this user"
        );
        require(msg.value >= offer.minValue, "Didn't send enough amount");
        require(
            ownerOf(doggyIndex) == offer.seller,
            "Seller no longer owner of doggy"
        );
        uint256 weiAmount = msg.value; 
        uint256 marketFee = weiAmount.div(marketFeeRate);
        uint256 saleFee =weiAmount.sub(marketFee);
        
        developer.transfer(marketFee);
        
        address seller = offer.seller;

        _safeTransfer(seller, msg.sender, doggyIndex, "");
        _doggyNoLongerForSale(doggyIndex);
        
        pendingWithdrawals[seller] += saleFee;  

        emit DoggyBought(doggyIndex, saleFee, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = doggyBids[doggyIndex];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;

            doggyBids[doggyIndex] = Bid(false, doggyIndex, address(0), 0);
        }
    }

    function withdraw() public reentrancyGuard {
        uint256 amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function enterBidForDoggy(uint256 doggyIndex) public payable reentrancyGuard {
        require(marketPaused == false, "Market Paused");
        require(doggyIndex < 100000, "doggy number is wrong");
        require(
            ownerOf(doggyIndex) != msg.sender,
            "you can not bid on your doggy"
        );
        require(msg.value > 0, "bid can not be zero");
        Bid memory existing = doggyBids[doggyIndex];
        require(
            msg.value > existing.value,
            "you can not bid lower than last bid"
        );
        if (existing.value > 0) {
            // Refund the failing bid

            pendingWithdrawals[existing.bidder] += existing.value;
        }

        doggyBids[doggyIndex] = Bid(true, doggyIndex, msg.sender, msg.value);

        emit DoggyBidEntered(doggyIndex, msg.value, msg.sender);
    }

    function acceptBidForDoggy(uint256 doggyIndex, uint256 minPrice)
        public
        reentrancyGuard
        onlyTokenOwner(doggyIndex)
    {
        require(marketPaused == false, "Market Paused");
        address seller = msg.sender;
        Bid memory bid = doggyBids[doggyIndex];
        require(bid.value > 0, "there is not any bid");
        require(bid.value >= minPrice, "bid is lower than min price");

        _doggyNoLongerForSale(doggyIndex);
        _safeTransfer(seller, bid.bidder, doggyIndex, "");

        uint256 amount = bid.value;
        uint256 bidFee = amount.div(marketFeeRate);
        uint256 saleFee = amount.sub(bidFee);
        
        totalMarketFee = totalMarketFee.add(bidFee);
        
        doggyBids[doggyIndex] = Bid(false, doggyIndex, address(0), 0);

        pendingWithdrawals[seller] += saleFee;
        emit DoggyBought(doggyIndex, saleFee, seller, bid.bidder);
    }
    
    function claimPendingRevenue() public reentrancyGuard onlyDeployer{
        uint256 amount = totalMarketFee;
        // sending to prevent re-entrancy attacks
        deployer.transfer(amount);
        // Remember to zero the pending refund before
        totalMarketFee = 0;
    }
    
        // Update the market fee
    function setCommissionRate(uint256 _marketFeeRate) public reentrancyGuard onlyDeployer {
        require(_marketFeeRate >= MAXIMUM_COMMISSION_RATE, "setCommissionRate: invalid market commission rate basis points");
        marketFeeRate = _marketFeeRate;
    }
        
        // Claim pending market fee
    function claimPendingCommission() public reentrancyGuard onlyDeployer() {
         address payable _owner = msg.sender;
        // sending to prevent re-entrancy attacks
        _owner.transfer(address(this).balance);
    }
    
    function withdrawBidForDoggy(uint256 doggyIndex) public reentrancyGuard {
        require(doggyIndex < 10000, "doggy number is wrong");
        require(ownerOf(doggyIndex) != msg.sender, "wrong action");
        require(
            doggyBids[doggyIndex].bidder == msg.sender,
            "Only bidder can withdraw"
        );

        Bid memory bid = doggyBids[doggyIndex];
        emit DoggyBidWithdrawn(doggyIndex, bid.value, msg.sender);
        uint256 amount = bid.value;
        doggyBids[doggyIndex] = Bid(false, doggyIndex, address(0), 0);
        // Refund the bid money
        msg.sender.transfer(amount);
    }
     /**
     * @notice Allows the owner to recover tokens sent to the contract by mistake
     * @param _token: token address
     * @dev Callable by owner
     */
    function recoverFungibleTokens(address _token) external onlyDeployer {
        uint256 amountToRecover = IERC20(_token).balanceOf(address(this));
        require(amountToRecover != 0, "Operations: No token to recover");

        IERC20(_token).safeTransfer(address(msg.sender), amountToRecover);

        emit TokenRecovery(_token, amountToRecover);
    }

    /**
     * @notice Allows the owner to recover NFTs sent to the contract by mistake
     * @param _token: NFT token address
     * @param _tokenId: tokenId
     * @dev Callable by owner
     */
    function recoverNonFungibleToken(address _token, uint256 _tokenId) external onlyDeployer {
        IERC721(_token).safeTransferFrom(address(this), address(msg.sender), _tokenId);

        emit NonFungibleTokenRecovery(_token, _tokenId);
    }
}