/**
 *Submitted for verification at snowtrace.io on 2021-12-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract Owner {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
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

contract YetiV2 is Owner {
    
    function reserveYeti(uint256 tokenId, address to) external onlyOwner {}
    
    function transferOwnership(address newOwner) public override onlyOwner {}
}

contract Master is Owner {
    
    YetiV2 yeti;
    
    address contractAddress;
    uint256[] arrayIds;
    uint256 YETI_TO_ASSIGN = 3088;
    uint256 counter;
    bool START_SALE;
    
    constructor(address _contractAddress) {
        yeti = YetiV2(_contractAddress);
    }
    
    
    function callMint(uint256 amount) external payable {
        require(msg.value == amount * (1 ether), "Bad amount");
        require(amount < 11);
        require(START_SALE == true);
        
        for(uint256 i = 0; i < amount; i++) {
            require(counter < arrayIds.length, "Try minting less");
            try yeti.reserveYeti(arrayIds[counter], msg.sender) {
                counter++;
            } catch {
                counter++;
            }
        }
    }
    
    function withdraw() external onlyOwner {
        address payable _owner = payable(owner());
        _owner.transfer(address(this).balance);
    }
    
    function Store(uint256[] memory toStore) external onlyOwner {
        for(uint256 i = 0; i < toStore.length; i++) {
            arrayIds.push(toStore[i]);
        }
    }
    
    function newOwner(address _newOwner) external onlyOwner {
        yeti.transferOwnership(_newOwner);
    }
    
    function mintForAidrop(uint256 tokenId, address to) external onlyOwner {
        yeti.reserveYeti(tokenId, to);
    }
    
    function start(bool action) external onlyOwner {
        START_SALE = action;
    }
}