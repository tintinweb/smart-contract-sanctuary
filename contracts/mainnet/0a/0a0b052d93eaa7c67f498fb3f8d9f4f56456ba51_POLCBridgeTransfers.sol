/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

// SPDX-License-Identifier: MIT


pragma solidity 0.8.2;

interface IERC20Token {
    function totalSupply() external view returns (uint256 supply);
    function transfer(address _to, uint256 _value) external  returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    function mint(address account, uint256 value) external returns (bool);
}

interface POLCProfits {
    function addBankEarnings(uint256 _amount) external;
}

library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }


    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

   
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

   
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

   
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

  
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract POLCBridgeTransfers is Context {
    event BridgeTransfer(address indexed from, address indexed to, uint256 amount, uint256 gasFee);

    address payable public bankVault;
    address public feesVault;
    address public polcTokenAddress;
    uint256 public bridgeFee;
    uint256 public gasFee;
    IERC20Token private polcToken;
    POLCProfits public profitsContract;
    mapping (uint8 => address) public managers;
    mapping (bytes32 => bool) public executedTask;

    uint16 public taskIndex;
    
    modifier isManager() {
        require(managers[0] == msg.sender || managers[1] == msg.sender || managers[2] == msg.sender, "Not manager");
        _;
    }
    
    constructor() {
        polcTokenAddress = 0xaA8330FB2B4D5D07ABFE7A72262752a8505C6B37;
        polcToken = IERC20Token(polcTokenAddress);
        bankVault = payable(0xf7A9F6001ff8b499149569C54852226d719f2D76);
        feesVault = 0xf7A9F6001ff8b499149569C54852226d719f2D76;
        
        managers[0] = msg.sender;
        managers[1] = 0xeA50CE6EBb1a5E4A8F90Bfb35A2fb3c3F0C673ec;
        managers[2] = 0xB1A951141F1b3A16824241f687C3741459E33225;
        bridgeFee = 1;
        gasFee = (1 gwei)*70000;
    }

    function bridgeSend(address _receiver, uint256 _amount) public payable returns (bool) {
        require((_amount>=(50 ether) && _amount<=(50000 ether)), "Invalid amount");
        require(msg.value >= gasFee, "Invalid gas fee");
        uint256 fee;
        if (bridgeFee > 0) {
            fee = (_amount * bridgeFee) /100;  // bridge transaction fee
            profitsContract.addBankEarnings((fee / 20)); //25% of the fees goes to bank hodlers, 5 banks = 5% each
        }
        uint256 transferAmount = _amount-fee;
        Address.sendValue(bankVault, msg.value);
        require(polcToken.transferFrom(msg.sender, feesVault, _amount));
        emit BridgeTransfer(msg.sender, _receiver, transferAmount, msg.value);
        return true;
    }
    
    function setBankVault(address _vault, bytes memory _sig) public isManager {
        uint8 mId = 1;
        bytes32 taskHash = keccak256(abi.encode(_vault, taskIndex, mId));
        verifyApproval(taskHash, _sig);
        bankVault = payable(_vault);
    }
    
    function setFeesVault(address _vault, bytes memory _sig) public isManager {
        uint8 mId = 2;
        bytes32 taskHash = keccak256(abi.encode(_vault, taskIndex, mId));
        verifyApproval(taskHash, _sig);
        feesVault = _vault;
    }
    
    function setFee(uint256 _fee, bytes memory _sig) public isManager {
        uint8 mId = 3;
        bytes32 taskHash = keccak256(abi.encode(_fee, taskIndex, mId));
        verifyApproval(taskHash, _sig);
        bridgeFee = _fee;   
    }
    
    function setProfitsContract(address _contract, bytes memory _sig) public isManager {
        uint8 mId = 4;
        bytes32 taskHash = keccak256(abi.encode(_contract, taskIndex, mId));
        verifyApproval(taskHash, _sig);
        profitsContract = POLCProfits(_contract);
    }

    function setGasFee(uint256 _fee, bytes memory _sig) public isManager {
        uint8 mId = 5;
        bytes32 taskHash = keccak256(abi.encode(_fee, taskIndex, mId));
        verifyApproval(taskHash, _sig);
        gasFee = _fee;
    }
    
    function verifyApproval(bytes32 _taskHash, bytes memory _sig) private {
        require(executedTask[_taskHash] == false, "Task already executed");
        address mSigner = ECDSA.recover(ECDSA.toEthSignedMessageHash(_taskHash), _sig);
        require(mSigner == managers[0] || mSigner == managers[1] || mSigner == managers[2], "Invalid signature"  );
        require(mSigner != msg.sender, "Signature from different managers required");
        executedTask[_taskHash] = true;
        taskIndex += 1;
    }
    
    function changeManager(address _manager, uint8 _index, bytes memory _sig) public isManager {
        require(_index >= 0 && _index <= 2, "Invalid index");
        uint8 mId = 100;
        bytes32 taskHash = keccak256(abi.encode(_manager, taskIndex, mId));
        verifyApproval(taskHash, _sig);
        managers[_index] = _manager;
    }
    

    
}