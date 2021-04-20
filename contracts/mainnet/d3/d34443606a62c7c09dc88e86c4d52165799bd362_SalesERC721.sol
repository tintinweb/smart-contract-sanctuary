/**
 *Submitted for verification at Etherscan.io on 2021-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

// File: @openzeppelin/contracts/GSN/Context.sol
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

//----------------------------==
//import "../../introspection/IERC165.sol";
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


//import "../../introspection/ERC165.sol";
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

//import "./IERC721.sol";
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    //added
    function exists(uint256 _tokenId) external view returns (bool);

}


//import "./IERC721Metadata.sol";
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

//import "./IERC721Enumerable.sol";
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


interface IERC721Full is IERC165, IERC721Metadata, IERC721Enumerable {}

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
//import "./ERC721NFT.sol";

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
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

// File: @openzeppelin/contracts/math/SafeMath.sol
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    // function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    //     return mod(a, b, "SafeMath: modulo by zero");
    // }

    // function mod(
    //     uint256 a,
    //     uint256 b,
    //     string memory errorMessage
    // ) internal pure returns (uint256) {
    //     require(b != 0, errorMessage);
    //     return a % b;
    // }
}


// File: @openzeppelin/contracts/utils/Address.sol
//pragma solidity >=0.6.2 <0.8.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
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

    // function sendValue(address payable recipient, uint256 amount) internal {
    //     require(
    //         address(this).balance >= amount,
    //         "Address: insufficient balance"
    //     );

    //     // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    //     (bool success, ) = recipient.call{value: amount}("");
    //     require(
    //         success,
    //         "Address: unable to send value, recipient may have reverted"
    //     );
    // }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    // function functionCall(address target, bytes memory data)
    //     internal
    //     returns (bytes memory)
    // {
    //     return functionCall(target, data, "Address: low-level call failed");
    // }

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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

// functionStaticCall x2

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
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol
// pragma solidity >=0.6.0 <0.8.0;
// import "./IERC20.sol";
// import "../../math/SafeMath.sol";
// import "../../utils/Address.sol";

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata =
            address(token).functionCall(
                data,
                "SafeERC20: low-level call failed"
            );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}
//import "./openzeppelinERC20ITF.sol";

contract MultiSig {
    using Address for address;

    address public assetOwner;
    address public addrNFTContract;

    event AssetOwnerVoteEvent(address indexed assetOwner, uint256 timestamp);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        require(msg.sender == assetOwner, "sender must be assetOwner");
        _;
    }

    function isAssetOwner() public view returns (bool) {
        return (msg.sender == assetOwner);
    }

    function setNFTAddr(address _addrNFT) external onlyOwner {
        addrNFTContract = _addrNFT;
    }

    function transferOwnership(address _owner) external onlyOwner {
        require(_owner != address(0), "invalid input");
        emit OwnershipTransferred(assetOwner, _owner);
        assetOwner = _owner;
    }
}

contract AssetBookNFT is MultiSig {
    using Address for address;
    IERC721Full public ierc721Full;

    constructor(address owner, address _addrNFT) {
        require(owner != address(0) && _addrNFT != address(0), "input invalid");
        require(owner.isContract() == false, "owner should not be a contract");
        assetOwner = owner;
        addrNFTContract = _addrNFT;
        ierc721Full = IERC721Full(address(_addrNFT));
    }

    function balanceOf(address owner) external view returns (uint256 balance) {
        return ierc721Full.balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) external view returns (address owner) {
        return ierc721Full.ownerOf(tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        ierc721Full.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external {
        ierc721Full.safeTransferFrom(from, to, tokenId, data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        ierc721Full.transferFrom(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) external {
        ierc721Full.approve(to, tokenId);
    }

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator)
    {
        return ierc721Full.getApproved(tokenId);
    }

    function setApprovalForAll(address operator, bool _approved) external {
        ierc721Full.setApprovalForAll(operator, _approved);
    }

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool)
    {
        return ierc721Full.isApprovedForAll(owner, operator);
    }

    //--------------==
    function name() external view returns (string memory) {
        return ierc721Full.name();
    }

    function symbol() external view returns (string memory) {
        return ierc721Full.symbol();
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return ierc721Full.tokenURI(tokenId);
    }

    function totalSupply() external view returns (uint256) {
        return ierc721Full.totalSupply();
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId)
    {
        return ierc721Full.tokenOfOwnerByIndex(owner, index);
    }

    function tokenByIndex(uint256 index) external view returns (uint256) {
        return ierc721Full.tokenByIndex(index);
    }

    //--------------==

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It mu
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external{
      ierc721Full.safeTransferFrom(from, to, tokenId, data);
    }st return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        require(operator != address(0), "operator address should not be zero"); // _from address is contract address if minting tokens
        require(from != address(0), "from address should not be zero"); // _from address is contract address if minting tokens
        //require(to != address(0), "original EOA should not be zero");
        require(tokenId > 0, "tokenId should be greater than zero");

        return _ERC721_RECEIVED;
    }
    // Equals to `bytes4(keccak256(abi.encodePacked("tokenReceiver(address,address,uint256)")))`
    /* $notice Handle the receipt of an NFT
    $dev The ERC721 smart contract calls this function on the recipient
      after a `transfer`. This function MAY throw to revert and reject the
      transfer. Return of other than the magic value MUST result in the
      transaction being reverted.
    */

    //function() external payable { revert("should not send any ether directly"); }
}

//--------------------==
/** gasLimit: 2140282  */
contract SalesERC721 is AssetBookNFT {
    using SafeERC20 for IERC20;

    uint256 public priceInWeiETH;
    uint256 public priceInWeiToken;
    IERC20 public token;

    event WithdrawETH(address indexed payee, uint256 amount, uint256 balance);
    event WithdrawERC20(address indexed payee, uint256 amount, uint256 balance);
    event BuyNFTViaETH(
        address indexed payer,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 balance
    );
    event BuyNFTViaERC20(
        address indexed payer,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 balance
    );

    constructor(
        address _owner,
        address _addrNFT 
    ) AssetBookNFT(_owner, _addrNFT) {
    //) AssetBookNFT(0x22202c0dF1f47E06303fCDe7F25bB0ef0429d61E, 0xF2956f502d61bfFec17fB631d7d139a0ff0848b2) {
        // require(_owner != address(0) && _addrNFT != address(this),"invalid addresses");

        priceInWeiETH = 250000000000000000;
        require(priceInWeiETH > 0, "invalid priceInWeiETH");
    }// 000000000000000000000000ARG000000000000000000000000ARG000000000000000000000000000000000000000000000000016345785d8a0000

    function BuyNFTViaETHCheck(uint256 _tokenId)
        external
        view
        returns (
            bool isActive,
            bool msgSenderOk,
            uint256 priceInWeiETH_,
            bool tokenIdOk
        )
    {
        return (
            !paused,
            msg.sender != address(0) && msg.sender != address(this),
            priceInWeiETH,
            ierc721Full.exists(_tokenId)
        );
    }

    /**
     * @dev Buy _tokenId
     * @param _tokenId uint256 token ID (painting number)
     */
    function buyNFTViaETH(uint256 _tokenId) external payable whenNotPaused {
        require(msg.sender != address(0) && msg.sender != address(this));
        require(msg.value >= priceInWeiETH);
        require(ierc721Full.exists(_tokenId));

        address tokenSeller = ierc721Full.ownerOf(_tokenId);
        ierc721Full.safeTransferFrom(tokenSeller, msg.sender, _tokenId);
        emit BuyNFTViaETH(
            msg.sender,
            _tokenId,
            msg.value,
            address(this).balance
        );
    }

    function buyNFTViaERC20(uint256 _tokenId) external whenNotPaused {
        require(msg.sender != address(0) && msg.sender != address(this));
        require(ierc721Full.exists(_tokenId));

        token.safeTransferFrom(msg.sender, address(this), priceInWeiToken);
        //require(msg.value >= priceInWeiETH);

        address tokenSeller = ierc721Full.ownerOf(_tokenId);
        ierc721Full.safeTransferFrom(tokenSeller, msg.sender, _tokenId);
        emit BuyNFTViaERC20(
            msg.sender,
            _tokenId,
            priceInWeiToken,
            address(this).balance
        );
    }

    /**
     * @dev send / withdraw _amount to _to
     */
    function withdrawETH(address payable _to, uint256 _amount)
        external
        onlyOwner
    {
        require(_to != address(0) && _to != address(this));
        require(_amount > 0 && _amount <= address(this).balance);
        _to.transfer(_amount);
        emit WithdrawETH(_to, _amount, address(this).balance);
    }

    function withdrawERC20(address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0) && _to != address(this));
        require(_amount > 0 && _amount <= token.balanceOf(address(this)));
        token.safeTransfer(_to, _amount);
        emit WithdrawERC20(_to, _amount, token.balanceOf(address(this)));
    }

    fallback() external payable {}

    receive() external payable {
        //called when the call data is empty
        if (msg.value > 0) {
            revert();
        }
    }

    //----------------------== Setting Functions
    /**
     * @dev Updates _priceInWeiETH
     * @dev Throws if _priceInWeiETH is zero
     */
    function setPriceInWeiETH(uint256 _priceInWeiETH) external onlyOwner {
        require(_priceInWeiETH > 0, "input invalid");
        priceInWeiETH = _priceInWeiETH;
    }

    function setPriceInWeiToken(uint256 _priceInWeiToken) external onlyOwner {
        require(_priceInWeiToken > 0, "input invalid");
        priceInWeiToken = _priceInWeiToken;
    }

    function setToken(address _token) external onlyOwner {
        require(_token != address(0), "input invalid");
        token = IERC20(_token);
    }

    //----------------------==
    event Paused(address account);
    event Unpaused(address account);
    bool public paused;

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }
    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    function _pause() external whenNotPaused onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() external whenPaused onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }
}