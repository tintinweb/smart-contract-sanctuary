/**
 *Submitted for verification at Etherscan.io on 2021-10-30
*/

// File: contracts/proxy/PriceViewV1Interface.sol

pragma solidity ^0.6.10;

interface  PriceViewV1Interface {
    function getUnderlyingPrice(address slToken) external view returns(uint256);
}

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
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



pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// File: contracts/proxy/PriceProxy.sol

pragma solidity ^0.6.10;



// current price getter
contract PriceProxy is Ownable {
//    The order of view's address.
    address[] views;
    //  init
    constructor(address[] memory _address) public {
        setViews(_address);
    }
    //    event
    event _SetViewsEvent(uint _order, address _addr);

    //  _order:fetch order , _addr: orcale views address
    function resetViews(address[] calldata _addr) external onlyOwner {
        setViews(_addr);
    }
    //  config orders
    function setViews(address[] memory _address) internal {
        delete views;
        for (uint i = 0; i < _address.length; i++) {
            views.push(_address[i]);
            emit _SetViewsEvent(i, _address[i]);
        }
    }

    // get lastest price from defferent views in order. stop lookup when get the sltoken price
    function getLastestUnderlyingPrice(address slToken) public view returns (uint){
        for (uint32 i = 0; i < views.length; i++) {
            uint underlyingPrice = uint256(PriceViewV1Interface(views[i]).getUnderlyingPrice(slToken));
            if (underlyingPrice <= 0) {
                continue;
            }
            return underlyingPrice;
        }
        // caller need judge the value;
        return 0;
    }

}