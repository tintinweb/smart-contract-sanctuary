// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./access/MedievalAccessControlled.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interface/IMedievalNFT.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NFTMinterWhiteList is MedievalAccessControlled, ReentrancyGuard{
    IMedievalNFT immutable public nft;

    mapping(address => bool) purchased;

    uint256 public immutable occupation;
    uint256 public price; // eth acmount
    bytes32 root; // Merckle root of the whitelist
    
    constructor(
        address _controlCenter,
        address _nft,
        uint256 _price,
        uint256 _occupation,
        bytes32 _root
    ){
        _setControlCenter(_controlCenter, msg.sender);
        nft = IMedievalNFT(_nft);
        price = _price;
        occupation = _occupation;
        root = _root;
    }

    function setRoot(bytes32 _root) external onlyAdmin {
        root = _root;
    }

    function setPrice(uint256 _price) external onlyAdmin {
        price = _price;
    }

    function mint(bytes32[] calldata proof) external nonReentrant payable{
        require(!purchased[msg.sender], "Already Purchased!");
        require(
            MerkleProof.verify(proof, root, keccak256(abi.encode(msg.sender))),
            "Not in the whitelist!"
        );
        uint256 value = msg.value;

        require(value == price, "Incorrect ETH Amount.");
        payable(_dao()).transfer(value);

        purchased[msg.sender] = true;
        nft.mint(msg.sender, occupation);
    }

    function destruct() external onlyAdmin {
        selfdestruct(payable(_dao()));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.7.0;
import "./interface/IMedievalAccessControlCenter.sol";

contract MedievalAccessControlled {   
    string constant ACCESS_DENIED_MSG = "Access Denied!"; 
    
    bytes32 constant DEFAULT_ADMIN_ROLE = 0;

    IMedievalAccessControlCenter public controlCenter;
    
    // tempAdmin has all the priviledge, and it is only used when controlCenter is not set.
    address public tempAdmin; 

    function _setControlCenter(address _controlCenter, address _tempAdmin) internal {
        controlCenter = IMedievalAccessControlCenter(_controlCenter);
        if(_controlCenter == address(0)){
            tempAdmin =_tempAdmin;
        } else {
            tempAdmin = address(0);
            // Prevent setting controlCenter to an invalid address.
            require(
                controlCenter.getRoleMemberCount(DEFAULT_ADMIN_ROLE) > 0,
                "Invalid controlCenter address!"
            ); 
        }
    }

    function setControlCenter(address _controlCenter, address _tempAdmin) external onlyAdmin {
        _setControlCenter(_controlCenter, _tempAdmin);
    }

    function _hasRole(bytes32 role, address account) internal view returns(bool){
        return controlCenter.hasRole(role, account);
    }

    function _treasury() internal view returns(address){
        return controlCenter.treasury();
    }

    function _dao() internal view returns(address){
        return controlCenter.dao();
    }

    modifier onlyRole(bytes32 role) {
        if(address(controlCenter) == address(0)) {
            require(tempAdmin == msg.sender, ACCESS_DENIED_MSG);
        } else {
            require(_hasRole(role, msg.sender),
                ACCESS_DENIED_MSG);
        }
        _;
    }

    modifier onlyAdmin() {
        if(address(controlCenter) == address(0)) {
            require(tempAdmin == msg.sender, ACCESS_DENIED_MSG);
        } else {
            require(_hasRole(0, msg.sender),
                ACCESS_DENIED_MSG);
        }
        _;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >0.7.0;

interface IMedievalAccessControlCenter {
  function addressBook ( bytes32 ) external view returns ( address );
  function getRoleAdmin ( bytes32 role ) external view returns ( bytes32 );
  function getRoleMember ( bytes32 role, uint256 index ) external view returns ( address );
  function getRoleMemberCount ( bytes32 role ) external view returns ( uint256 );
  function grantRole ( bytes32 role, address account ) external;
  function hasRole ( bytes32 role, address account ) external view returns ( bool );
  function renounceRole ( bytes32 role, address account ) external;
  function revokeRole ( bytes32 role, address account ) external;
  function setAddress ( bytes32 id, address _address ) external;
  function setRoleAdmin ( bytes32 role, bytes32 adminRole ) external;
  function treasury (  ) external view returns ( address );
  function dao (  ) external view returns ( address );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMedievalNFT {
    function setMinter(address _minte) external;
    function mint(address to, uint256 occupation) external;
}