// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

interface ICarbSwapProvider {
    function getFundPoolWhiteList() external view returns (address[] memory);

    function verifyFundPoolWhiteList(address) external view returns (bool);

    function addFundPoolWhiteList(address) external;

    function subFundPoolWhiteList(address) external;

    function getFundPool() external view returns (address payable);

    function setFundPool(address payable pool) external;

    function getCarbSwapRouter() external returns (address);

    function setCarbSwapRouter(address router) external;

    function getTransactionCertificate() external returns (address);

    function setTransactionCertificate(address nft) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "../interface/ICarbSwapProvider.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CarbSwapProvider is ICarbSwapProvider, Ownable {
    address[] private _whiteList;

    mapping(address => uint256) private _whiteListIndex;

    address payable private _fundPool;

    address private _router;

    address private _nft;

    constructor() Ownable() {
        _whiteList.push();
    }

    function getFundPoolWhiteList()
        external
        view
        override
        returns (address[] memory addresses)
    {
        addresses = _whiteList;
    }

    function verifyFundPoolWhiteList(address _address)
        external
        view
        override
        returns (bool)
    {
        return _whiteListIndex[_address] != 0;
    }

    function addFundPoolWhiteList(address _address) public override onlyOwner {
        require(_whiteListIndex[_address] == 0, "CSP: Address already exists");
        _whiteListIndex[_address] = _whiteList.length;
        _whiteList.push(_address);
        emit AddWhiteListAddress(_address);
    }

    //The length of the array does not decrease after deletion
    function subFundPoolWhiteList(address _address) public override onlyOwner {
        uint256 index = _whiteListIndex[_address];
        require(index != 0, "CSP: WhiteList not have this address");
        delete _whiteList[index];
        delete _whiteListIndex[_address];
        emit SubWhiteListAddress(_address);
    }

    function getFundPool() public view override returns (address payable) {
        return _fundPool;
    }

    function setFundPool(address payable pool) external override onlyOwner {
        address old = _fundPool;
        _fundPool = pool;
        emit EditUsdtFoolPoolAddress(old, pool);
    }

    function getCarbSwapRouter() external view override returns (address) {
        return _router;
    }

    function setCarbSwapRouter(address router) external override onlyOwner {
        address old = _router;
        _router = router;
        emit EditRouterAddress(old, router);
    }

    function getTransactionCertificate()
        external
        view
        override
        returns (address)
    {
        return _nft;
    }

    function setTransactionCertificate(address nft)
        external
        override
        onlyOwner
    {
        address old = _nft;
        _nft = nft;
        emit EditRouterAddress(old, nft);
    }

    event AddWhiteListAddress(address _address);

    event SubWhiteListAddress(address _address);

    event EditUsdtFoolPoolAddress(address _old, address _new);

    event EditRouterAddress(address _old, address _new);

    event EditTransactionCertificateAddress(address _old, address _new);
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