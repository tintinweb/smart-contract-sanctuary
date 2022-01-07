// pragma solidity ^0.8.0;
// import "./bridgeBase.sol";
// import "hardhat/console.sol";

// contract ETHBridge is BridgeBase {
//     constructor(address token, address _validator) BridgeBase(token, _validator) {}

//     uint256 nonce_count;

//     function depositTokens(
//         uint256 amount,
//         address recipient
//     ) external override {
 
 
      
//         token.burn(msg.sender, amount);

//         nonce_count += 1;
//         bytes32 txHash = keccak256(abi.encode(amount, nonce_count, recipient, msg.sender));

//         bytes memory _transactionID = abi.encode(amount, nonce_count, recipient, msg.sender);
       
        


//         emit TokenDeposit(

//              txHash,
//             _transactionID
//         );
//     }

//     function withdrawTokens(

//         bytes32 _txHash,
//         bytes calldata _transactionID,
//         bytes calldata signature
        
//     ) external override {

//         (
//             uint256 _amount,
//             uint256 _nonce,
//             address _to,
//             address _from
//         ) = abi.decode(_transactionID, (uint256, uint256, address, address));
        
//         require(msg.sender == _to, "ETHBridge: Irrelevant reciever");
//         address signAddress;
     
//         bytes32 message = prefixed(
//             keccak256(abi.encodePacked(_from, _to, _amount, _nonce))
//         );
//         console.logBytes32(message);
   
//         signAddress = recoverSigner(message, signature);
      
        
//         require(validator == signAddress, "ETHBridge: wrong signature");

//         require(
//             !processedTransactions[_txHash],
//             "ETHBridge: transaction already processed"
//         );
//         processedTransactions[_txHash] = true;

//         token.mint(_to, _amount);

//         emit TokenWithdraw(_from, _to, _amount, _nonce, signature);
//     }
// }

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


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
        // _setOwner(_msgSender());
        
       // _owner = 0x992Cd46dfE21377bef5A5178F8b8349de2C37453;
       _owner = 0x611485C1990cd77A7D67e46AA6D6e7F8359dF4ee;
        emit OwnershipTransferred(address(0), _owner);
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
interface IToken {
    function transferOwnership(address newOwner) external;

    function mint(address to, uint256 amount) external;

    function burn(address owner, uint256 amount) external;

    function transfer(address recipient, uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 tokens)
        external
        returns (bool success);
}


abstract contract BridgeBase is Ownable{
    address public validator;
    IToken public token;
    bool public whiteListOn;
  mapping(address => bool) public isWhiteList;
    mapping(bytes32 => bool) internal processedTransactions;

    event TokenDeposit(
        bytes32 txHash,
        bytes transactionID
    );

    event TokenWithdraw(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 nonce,
        bytes sign
    );


event WhiteListToggled(bool state);









   event WhiteListAddressToggled(


       address _user,


       address _bridgeAddress,


       bool _state


   );




    constructor(address _token, address _validator) {
        require(_token != address(0), "Token cannot be 0 address");
        require(_validator != address(0), "Admin cannot be 0 address");
        token = IToken(_token);
        validator = _validator;
    whiteListOn = !whiteListOn;
     
    }
    
   function prefixed(bytes32 hash) internal pure returns (bytes32) {
       
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return recover(message, v, r, s);
    }

    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n / 2 + 1, and for v in (282): v in {27, 28 Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65, "sig length invalid");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function depositTokens(
        uint256 amount,
        address recipient
    ) external virtual;

    function withdrawTokens(
        bytes32 _txHash,
        bytes calldata _transactionID,
        bytes calldata signature
    ) external virtual;


function toggleWhiteListOnly() external onlyOwner {




       //require(msg.sender == owner, "Sender not Owner");


       whiteListOn = !whiteListOn;


       emit WhiteListToggled(whiteListOn);


   }







   function toggleWhiteListAddress(address[] calldata _addresses)


       external


       onlyOwner


   {


       // require(msg.sender == owner, "Sender not Owner");


       require(_addresses.length <= 200, "Addresses length exceeded");


       for (uint256 i = 0; i < _addresses.length; i++) {


           isWhiteList[_addresses[i]] = !isWhiteList[_addresses[i]];


           emit WhiteListAddressToggled(


               _addresses[i],


               address(this),


               isWhiteList[_addresses[i]]


           );


       }


   }



}
contract ETHBridge is BridgeBase {
    constructor(address token, address _validator) BridgeBase(token, _validator) {}

    uint256 nonce_count;

    function depositTokens(
        uint256 amount,
        address recipient
    ) external override {
 
       
require(




           !whiteListOn || isWhiteList[msg.sender],


           "ETHBridge: Forbidden in White List mode"


       );


      
        token.burn(msg.sender, amount);

        nonce_count += 1;
        bytes32 txHash = keccak256(abi.encode(amount, nonce_count, recipient, msg.sender));

        bytes memory _transactionID = abi.encode(amount, nonce_count, recipient, msg.sender);
       
        


        emit TokenDeposit(

             txHash,
            _transactionID
        );
    }

    function withdrawTokens(

        bytes32 _txHash,
        bytes calldata _transactionID,
        bytes calldata signature
        
    ) external override {


require(




           !whiteListOn || isWhiteList[msg.sender],


           "ETHBridge: Forbidden in White List mode"


       );



        (
            uint256 _amount,
            uint256 _nonce,
            address _to,
            address _from
        ) = abi.decode(_transactionID, (uint256, uint256, address, address));
        
        require(msg.sender == _to, "ETHBridge: Irrelevant receiver");
        address signAddress;
     
        bytes32 message = prefixed(
            keccak256(abi.encodePacked(_from, _to, _amount, _nonce))
        );
  
   
        signAddress = recoverSigner(message, signature);
      
        
        require(validator == signAddress, "ETHBridge: wrong signature");

        require(
            !processedTransactions[_txHash],
            "ETHBridge: transaction already processed"
        );
        processedTransactions[_txHash] = true;

        token.mint(_to, _amount);

        emit TokenWithdraw(_from, _to, _amount, _nonce, signature);
    }
}