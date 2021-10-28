/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

// Sources flattened with hardhat v2.6.7 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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


// File contracts/IdentityOracle.sol

pragma solidity >0.8.0;

contract IdentityOracle is Ownable {
    address public dao_avatar; // this implementation is only to test. In live it would be replaced for dao.avatar

    bytes32 public stateHash;
    string public stateDataIPFS;

    uint256 public lastStartUpdProcInvoked;

    struct WhitelistProofState {
        uint256 lastProofDate;
        uint256 lastAuthenticatedDate;
    }

    mapping(address => WhitelistProofState) private whitelistProofState;

    mapping(address => bool) public oracleState; // Store oracle address ad if isAllowed

    event AddressWhitelisted(address addr, uint256 lastAuthenticationDate);

    constructor(address _avatar, address _oracle) Ownable() {
        dao_avatar = _avatar;
        oracleState[_oracle] = true;
    }

    function _onlyOracle() internal view {
        require(
            oracleState[msg.sender],
            "only allowed oracle can call this method"
        );
    }

    function _onlyAvatar() internal view {
        require(
            address(dao_avatar) == msg.sender,
            "only avatar can call this method"
        );
    }

    //- only the DAO can approve/remove an oracle. onlyAvatar is defined in DAOUpgradeableContract
    function setOracle(address _oracle, bool _isAllowed) public {
        _onlyAvatar();
        oracleState[_oracle] = _isAllowed;
    }

    // It's the second function to be called by the oracle to store the StateHash value and IPFSCID
    function setFulfillStateHashIPFSCID(bytes memory _statehashipfscid)
        public
    // This function is called only oracle
    //- only approved oracles can set the new merkle state plus link to ipfs data used to create state
    {
        _onlyOracle();
        (bytes32 _statehash, string memory _ipfscid) = abi.decode(
            _statehashipfscid,
            (bytes32, string)
        );
        stateHash = _statehash;
        stateDataIPFS = _ipfscid;
    }

    //- prove that pair publicAddress, lastAuthenticated exists in current state.
    //update address state in smart contract. also update address lastProofDate (required by isWhitelisted below).
    //Proof can be generated by "sdk" defined in previous step.
    function prove(
        address _address,
        uint256 _lastAuthenticated,
        bytes32[] memory _proof,
        uint256 _index
    ) public {
        bool result = false;
        bytes32 leafHash = keccak256(abi.encode(_address, _lastAuthenticated));

        result = checkProofOrdered(_proof, stateHash, leafHash, _index);

        //update address state in smart contract. also update address lastProofDate (required by isWhitelisted below).
        if (result) {
            WhitelistProofState memory state;
            state.lastProofDate = block.timestamp;
            state.lastAuthenticatedDate = _lastAuthenticated;
            whitelistProofState[_address] = state;
            emit AddressWhitelisted(_address, _lastAuthenticated);
        }
    }

    // from StorJ -- https://github.com/nginnever/storj-audit-verifier/blob/master/contracts/MerkleVerifyv3.sol
    /**
     * @dev non sorted merkle tree proof check
     */
    function checkProofOrdered(
        bytes32[] memory _proof,
        bytes32 _root,
        bytes32 _hash,
        uint256 _index
    ) public pure returns (bool) {
        // use the index to determine the node ordering
        // index ranges 1 to n

        bytes32 proofElement;
        bytes32 computedHash = _hash;
        uint256 remaining;

        for (uint256 j = 0; j < _proof.length; j++) {
            proofElement = _proof[j];

            // calculate remaining elements in proof
            remaining = _proof.length - j;

            // we don't assume that the tree is padded to a power of 2
            // if the index is odd then the proof will start with a hash at a higher
            // layer, so we have to adjust the index to be the index at that layer
            while (remaining > 0 && _index % 2 == 1 && _index > 2**remaining) {
                _index = _index / 2 + 1;
            }

            if (_index % 2 == 0) {
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
                _index = _index / 2;
            } else {
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
                _index = _index / 2 + 1;
            }
        }

        return computedHash == _root;
    }

    //- returns true if address is whitelisted under maxProofAge and maxAuthentication age restrictions.
    //maxProofAge should be compared to lastProofDate and maxAuthenticationAge to lastAuthenticated.
    //if 0 is supplied then they are ignored.
    function isWhitelisted(
        address _address,
        uint256 _maxProofAgeInDays,
        uint256 _maxAuthenticationAgeInDays
    ) public view returns (bool) {
        bool result = false;
        WhitelistProofState memory state = whitelistProofState[_address];
        if (state.lastProofDate > 0) {
            if (
                (_maxAuthenticationAgeInDays == 0 ||
                    state.lastAuthenticatedDate >
                    block.timestamp - _maxAuthenticationAgeInDays * 1 days) &&
                (_maxProofAgeInDays == 0 ||
                    state.lastProofDate >
                    block.timestamp - _maxProofAgeInDays * 1 days)
            ) {
                result = true;
            }
        }
        return result;
    }
}