/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

// Sources flattened with hardhat v2.6.1 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/proxy/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}


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


// File contracts/interfaces/ILaunchPad.sol

pragma solidity >=0.8.0;

/**
 * 
 */
interface ILaunchPad {
    function transferOwnership(address _owner) external;
    function addManyToWhitelist(address[] memory _beneficiaries) external;
}


// File contracts/interfaces/IToken.sol

pragma solidity >=0.8.0;

/**
 * 
 */
interface IToken {
    function pause() external;
    function transferOwnership(address _owner) external;
}


// File contracts/LaunchPadFactory.sol

pragma solidity ^0.8.4;




struct LaunchPadParam {
    bool _isWhitelist;
    address[] _whitelists;
    uint256 _rate;
    address _wallet;
    uint256 _cap;
    uint256 _openingTime;
    uint256 _closingTime;
    uint256 _goal;
    address _foundersFund;
    address _foundationFund;
    address _partnersFund;
    uint256 _releaseTime;
}

struct TokenParam {
    string _name;
    string _symbol;
    uint8 _decimals;
}

/**
 * @title LaunchPadFactory
 * @dev LaunchPadFactory contract
 * 
 *
 */
contract LaunchPadFactory is Ownable {
    address public tokenImplementation;
    address public launchPadImplementation;

    event TokenCreated(address token);
    event LaunchPadCreated(address launchPad);

    constructor() {
    }

    function upgradeTokenImplementation(address _upgradedImplementation)
        external
        onlyOwner
    {
        require(_upgradedImplementation != address(0), "CF02");
        tokenImplementation = _upgradedImplementation;
    }

    function upgradeLPImplementation(address _upgradedImplementation)
        external
        onlyOwner
    {
        require(_upgradedImplementation != address(0), "CF03");
        launchPadImplementation = _upgradedImplementation;
    }

    function instantiateToken(
        TokenParam memory param
    ) internal returns (IToken) {
        IToken token =
            IToken(
                ClonesUpgradeable.cloneDeterministic(
                    tokenImplementation,
                    keccak256(
                        abi.encodePacked(
                            param._name, 
                            param._symbol, 
                            param._decimals
                        )
                    )
                )
            );
        emit TokenCreated(address(token));
        return token;
    }

    function instantiateLaunchPad(
        LaunchPadParam memory param,
        IToken _token,
        address _owner
    ) internal returns (ILaunchPad) {
        bytes32 cloneParam;

        {
            cloneParam = keccak256(
                abi.encodePacked(
                    param._rate, 
                    param._wallet, 
                    address(_token), 
                    param._cap, 
                    param._openingTime, 
                    param._closingTime, 
                    param._goal, 
                    param._foundersFund, 
                    param._foundationFund, 
                    param._partnersFund, 
                    param._releaseTime
                )
            );
        }
        ILaunchPad launchPad =
            ILaunchPad(
                ClonesUpgradeable.cloneDeterministic(
                    launchPadImplementation,
                    cloneParam
                )
            );
        _token.pause();
        _token.transferOwnership(address(launchPad));
        if (param._isWhitelist) {
            launchPad.addManyToWhitelist(param._whitelists);
        }
        launchPad.transferOwnership(_owner);
        emit LaunchPadCreated(address(launchPad));
        return launchPad;
    }

    function instantiate (
        TokenParam memory tokenParam,
        LaunchPadParam memory lauchPadParam
    ) external onlyOwner {

        IToken token = instantiateToken(
            tokenParam
        );

        instantiateLaunchPad(
            lauchPadParam,
            token,
            msg.sender
        );
    }
}