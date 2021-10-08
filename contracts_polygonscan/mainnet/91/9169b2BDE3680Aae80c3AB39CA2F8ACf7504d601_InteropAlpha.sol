/**
 *Submitted for verification at polygonscan.com on 2021-10-08
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File contracts/store/variables.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

contract Variables {
    mapping(bytes32 => bool) public executeMapping;
    uint256 public vnonce;
}


// File contracts/logic/events.sol

contract Events {
    struct spell {
        string connector;
        bytes data;
    }

    event validate(
        spell[] sourceSpells,
        spell[] targetSpells,
        uint256 sourceDsaId,
        uint256 targetDsaId,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 indexed vnonce
    );

    event sourceFailed(
        spell[] sourceSpells,
        spell[] targetSpells,
        uint256 sourceDsaId,
        uint256 targetDsaId,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 indexed vnonce
    );

    event execute(
        spell[] sourceSpells,
        spell[] targetSpells,
        uint256 sourceDsaId,
        uint256 targetDsaId,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 indexed vnonce
    );

    event TargetDsaInvalid(
        spell[] sourceSpells,
        spell[] targetSpells,
        uint256 sourceDsaId,
        uint256 targetDsaId,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 indexed vnonce
    );

    event TargetFailed(
        spell[] sourceSpells,
        spell[] targetSpells,
        uint256 sourceDsaId,
        uint256 targetDsaId,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 indexed vnonce
    );
}

interface ListInterface {
    struct UserLink {
        uint64 first;
        uint64 last;
        uint64 count;
    }

    struct UserList {
        uint64 prev;
        uint64 next;
    }

    struct AccountLink {
        address first;
        address last;
        uint64 count;
    }

    struct AccountList {
        address prev;
        address next;
    }

    function accounts() external view returns (uint);
    function accountID(address) external view returns (uint64);
    function accountAddr(uint64) external view returns (address);
    function userLink(address) external view returns (UserLink memory);
    function userList(address, uint64) external view returns (UserList memory);
    function accountLink(uint64) external view returns (AccountLink memory);
    function accountList(uint64, address) external view returns (AccountList memory);
}

interface AccountInterface {

    function version() external view returns (uint);

    function cast(
        string[] calldata _targetNames,
        bytes[] calldata _datas,
        address _origin
    )
    external
    payable 
    returns (bytes32);

    function castLimitOrder(
        address tokenFrom,
        address tokenTo,
        uint amountFrom,
        uint amountTo,
        uint32 _route,
        address ctokenFrom,
        address ctokenTo
    )
    external
    payable;

}


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


// File contracts/logic/InteropAlpha.sol

interface IndexInterface {
    function list() external view returns (address);
}

contract InteropAlpha is Variables, Events, Ownable {
    ListInterface public immutable list;

    constructor(address _instaIndex) {
        list = ListInterface(IndexInterface(_instaIndex).list());
    }

    /**
     * @dev Return chain Id
     */
    function getChainID() internal view returns (uint256) {
        return block.chainid;
    }

    /**
     * @dev cast sourceSpells
     */
    function sourceMagic(
        spell[] memory sourceSpells,
        spell[] memory targetSpells,
        uint64 targetDsaId,
        uint256 targetChainId
    ) external {
        vnonce = vnonce + 1;
        uint256 sourceChainId = getChainID();
        uint256 sourceDsaId = list.accountID(0x238f4De842208a478e1765e0388eF3B6deeB0784);
        // require(sourceDsaId != 0, "msg.sender-not-dsa");
        AccountInterface dsa = AccountInterface(0x238f4De842208a478e1765e0388eF3B6deeB0784);
        string[] memory connectors = new string[](sourceSpells.length);
        bytes[] memory callData = new bytes[](sourceSpells.length);
        for (uint256 i = 0; i < sourceSpells.length; i++) {
            connectors[i] = sourceSpells[i].connector;
            callData[i] = sourceSpells[i].data;
        }
        (bool success, ) = address(dsa).call(
            abi.encodeWithSignature(
                "cast(string[],bytes[],address)",
                connectors,
                callData,
                address(this)
            )
        );

        if (success) {
            emit validate(
                sourceSpells,
                targetSpells,
                sourceDsaId,
                targetDsaId,
                sourceChainId,
                targetChainId,
                vnonce
            );
        } else {
            emit sourceFailed(
                sourceSpells,
                targetSpells,
                sourceDsaId,
                targetDsaId,
                sourceChainId,
                targetChainId,
                vnonce
            );
        }
    }

    /**
     * @dev cast targetSpells
     */
    function targetMagic(
        spell[] memory sourceSpells,
        spell[] memory targetSpells,
        uint64 sourceDsaId,
        uint64 targetDsaId,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 _vnonce
    ) 
        external 
        // onlyOwner 
    {
        bytes32 key = keccak256(
            abi.encode(
                sourceSpells,
                targetSpells,
                sourceDsaId,
                targetDsaId,
                sourceChainId,
                targetChainId,
                _vnonce
            )
        );
        require(executeMapping[key] == false, "validation-failed");
        address targetDsaAddr = list.accountAddr(targetDsaId);
        if (targetDsaId > 0 && targetDsaAddr == address(0)) {
            emit TargetDsaInvalid(
                sourceSpells,
                targetSpells,
                sourceDsaId,
                targetDsaId,
                sourceChainId,
                targetChainId,
                _vnonce
            );
            return;
        }
        AccountInterface dsa = AccountInterface(targetDsaAddr);
        string[] memory connectors = new string[](targetSpells.length);
        bytes[] memory callData = new bytes[](targetSpells.length);
        for (uint256 i = 0; i < targetSpells.length; i++) {
            connectors[i] = targetSpells[i].connector;
            callData[i] = targetSpells[i].data;
        }
        (bool success, ) = address(dsa).call(
            abi.encodeWithSignature(
                "cast(string[],bytes[],address)",
                connectors,
                callData,
                msg.sender
            )
        );
        if (success) {
            executeMapping[key] = true;
            emit execute(
                sourceSpells,
                targetSpells,
                sourceDsaId,
                targetDsaId,
                sourceChainId,
                targetChainId,
                _vnonce
            );
        } else {
            emit TargetFailed(
                sourceSpells,
                targetSpells,
                sourceDsaId,
                targetDsaId,
                sourceChainId,
                targetChainId,
                _vnonce
            );
        }
    }
}