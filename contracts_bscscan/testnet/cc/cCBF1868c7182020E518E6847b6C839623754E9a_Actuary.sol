// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/ICohortFactory.sol";

contract Actuary is Ownable {
    address public claimAssessor;
    address[] public cohortCreators;
    uint256 public cohortCreateFee;

    event CohortCreated(address indexed cohort, address indexed owner);

    constructor(address _claimAssessor) {
        require(_claimAssessor != address(0), "UnoRe: ZERO_ADDRESS");
        claimAssessor = _claimAssessor;
    }

    modifier onlyCohortCreator() {
        require(isCohortCreator(msg.sender), "UnoRe: Forbidden");
        _;
    }

    function cohortCreatorsLength() external view returns (uint256) {
        return cohortCreators.length;
    }

    function addCohortCreator(address _creator) external onlyOwner {
        require(isCohortCreator(_creator) == false, "UnoRe: Already registered");
        cohortCreators.push(_creator);
    }

    function createCohort(
        address _cohortFactory,
        string memory _name,
        uint256 _cohortStartCapital,
        address _premiumFactory,
        address _premiumCurrency,
        uint256 _minPremium
    ) external payable onlyCohortCreator returns (address cohort) {
        require(owner() == msg.sender || msg.value == cohortCreateFee, "UnoRe: Incorrect creation fee");
        require(_premiumFactory != address(0), "UnoRe: ZERO_ADDRESS");
        require(_premiumCurrency != address(0), "UnoRe: ZERO_ADDRESS");
        cohort = ICohortFactory(_cohortFactory).newCohort(
            msg.sender,
            _name,
            claimAssessor,
            _cohortStartCapital,
            _premiumFactory,
            _premiumCurrency,
            _minPremium
        );

        emit CohortCreated(cohort, msg.sender);
    }

    function isCohortCreator(address _creator) public view returns (bool) {
        if (owner() == _creator) {
            return true;
        }
        uint256 len = cohortCreators.length;
        for (uint256 ii = 0; ii < len; ii++) {
            if (cohortCreators[ii] == _creator) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev when setting fee, please consider ETH decimal(8)
     */
    function setCohortCreationFee(uint256 _fee) external onlyOwner {
        cohortCreateFee = _fee;
    }

    function withdrawCreateFee(address _to) external onlyOwner {
        TransferHelper.safeTransferETH(_to, address(this).balance);
    }
}

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

// from Uniswap TransferHelper library
library TransferHelper {
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeTransfer: transfer failed");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::transferFrom: transferFrom failed");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface ICohortFactory {
    function newCohort(
        address _owner,
        string memory _name,
        address _claimAssessor,
        uint256 _cohortStartCapital,
        address _premiumFactory,
        address _premiumCurrency,
        uint256 _minPremium
    ) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

