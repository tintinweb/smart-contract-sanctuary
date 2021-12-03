// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "../interface/IBettingFactory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Factory is Ownable {
    mapping(PrizeBetting => address) public typeToAddress;

    enum PrizeBetting {
        GuaranteedPrizeFactory,
        StandardPrizeFactory,
        CommunityFactory,
        FreeFactory
    }

    constructor(
        address _guaranteed,
        address _standard,
        address _community,
        address _free
    ) {
        typeToAddress[PrizeBetting.GuaranteedPrizeFactory] = _guaranteed;
        typeToAddress[PrizeBetting.StandardPrizeFactory] = _standard;
        typeToAddress[PrizeBetting.CommunityFactory] = _community;
        typeToAddress[PrizeBetting.FreeFactory] = _free;
    }

    function setTypeToAddress(PrizeBetting _type, address _newAddr)
        public
        onlyOwner
    {
        typeToAddress[_type] = _newAddr;
    }

    function createNewFreeBettingContract(
        address payable _owner,
        address payable _creator,
        address _tokenPool,
        uint256 _fee
    ) external returns (address) {
        return
            IBettingFactory(typeToAddress[PrizeBetting.FreeFactory])
                .createNewBettingContract(_owner, _creator, _tokenPool, _fee);
    }

    function createNewCommunityBettingContract(
        address payable _owner,
        address payable _creator,
        address _tokenPool,
        uint256 _fee
    ) external returns (address) {
        return
            IBettingFactory(typeToAddress[PrizeBetting.CommunityFactory])
                .createNewBettingContract(_owner, _creator, _tokenPool, _fee);
    }

    function createNewStandardBettingContract(
        address payable _owner,
        address payable _creater,
        address _tokenPool,
        uint256 _rewardForWinner,
        uint256 _rewardForCreator,
        uint256 _decimal,
        uint256 _fee
    ) external returns (address) {
        return
            IBettingFactory(typeToAddress[PrizeBetting.StandardPrizeFactory])
                .createNewBettingContract(
                    _owner,
                    _creater,
                    _tokenPool,
                    _rewardForWinner,
                    _rewardForCreator,
                    _decimal,
                    _fee
                );
    }

    function createNewGuaranteedBettingContract(
        address payable _owner,
        address payable _creater,
        address _tokenPool,
        uint256 _rewardForWinner,
        uint256 _rewardForCreator,
        uint256 _decimal,
        uint256 _fee
    ) external returns (address) {
        return
            IBettingFactory(typeToAddress[PrizeBetting.GuaranteedPrizeFactory])
                .createNewBettingContract(
                    _owner,
                    _creater,
                    _tokenPool,
                    _rewardForWinner,
                    _rewardForCreator,
                    _decimal,
                    _fee
                );
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IBettingFactory {
    function createNewBettingContract(
        address payable _owner,
        address payable _creater,
        address _tokenPool,
        uint256 _fee
    ) external returns (address);

    function createNewBettingContract(
        address payable _owner,
        address payable _creater,
        address _tokenPool,
        uint256 _rewardForWinner,
        uint256 _rewardForCreator,
        uint256 _decimal,
        uint256 _fee
    ) external returns (address);
}