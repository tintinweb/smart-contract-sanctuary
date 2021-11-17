// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

/** @notice Dispatching received ETHs between given addresses depending on a ratio by /10000
            as solidity sucks with float numbers ...(i.e 20% -> 2000, 96,5% -> 9650)
    @author Loïs L. (discord: SnoW#3012) */
contract Dispatch is Ownable {
    /** @notice define the struct of Addr 
        @param ratio define the ratio /10000 to give rewards to this address 
        @param addr the address to give some rewards */
    struct Addr {
        address addr;
        uint ratio;
    }

    /** @dev contains addresses indexed by the ID */
    mapping (uint => Addr) private addresses;



    constructor(address _addr1, address _addr2, address _addr3){
        /// @dev initialize the contract with three manageable addresses
        addresses[1] = Addr(_addr1, 9650);
        addresses[2] = Addr(_addr2, 200);
        addresses[3] = Addr(_addr3, 150);
    }


    /** @notice return datas about the address 1 */
    function getAddress1() external view onlyOwner returns(Addr memory){
        return addresses[1];
    }

    /** @notice return datas about the address 1 */
    function getAddress2() external view onlyOwner returns(Addr memory){
        return addresses[2];
    }

    /** @notice return datas about the address 1 */
    function getAddress3() external view onlyOwner returns(Addr memory){
        return addresses[3];
    }

    /** @notice return datas about the address 1 
        @param _addr the new address to set */
    function setAddress1(address _addr) external onlyOwner {
        require(_addr != address(0), "can't be address 0");
        require(_addr != addresses[1].addr, "should set a NEW address");

        addresses[1].addr = _addr;
    }

    /** @notice return datas about the address 2
        @param _addr the new address to set */
    function setAddress2(address _addr) external onlyOwner {
        require(_addr != address(0), "can't be address 0");
        require(_addr != addresses[2].addr, "should set a NEW address");


        addresses[2].addr = _addr;
    }

    /** @notice return datas about the address 3 
        @param _addr the new address to set */
    function setAddress3(address _addr) external onlyOwner {
        require(_addr != address(0), "can't be address 0");
        require(_addr != addresses[3].addr, "should set a NEW address");


        addresses[3].addr = _addr;
    }

    /** @notice redefine the ratios for each address 
        @param _ratio1 the ratio of the address 1 
        @param _ratio2 the ratio of the address 2
        @param _ratio3 the ratio of the address 3 */
    function setRatios(uint _ratio1, uint _ratio2, uint _ratio3) external onlyOwner {
        require(_ratio1 + _ratio2 + _ratio3 == 10000, "incorrect ratios input");

        addresses[1].ratio = _ratio1;
        addresses[2].ratio = _ratio2;
        addresses[3].ratio = _ratio3;
    }

    /** @notice when ethers are send to the contract, it get dispatched between addresses as setup */
    receive() external payable {
        payable(addresses[1].addr).transfer(msg.value * addresses[1].ratio / 10000);
        payable(addresses[2].addr).transfer(msg.value * addresses[2].ratio / 10000);
        payable(addresses[3].addr).transfer(msg.value * addresses[3].ratio / 10000);
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