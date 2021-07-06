/**
 *Submitted for verification at polygonscan.com on 2021-07-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

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
        return msg.data;
    }
}


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


contract BDay is Ownable {
    
    string private target;
    Gift[] private gifts;
    
    
    struct Gift {
        
        uint id;
        uint256 am;
        string pass;
        address claimer;
        string data;
        
    }
    
    constructor(string memory _target) {
        
        target = _target;

    }
    
    
    function addGift(uint _id, string memory _pass, address _claimer, string memory _data) public payable onlyOwner  {
        
        gifts.push(Gift(_id, msg.value, _pass, _claimer, _data));

    }
    
    function getGift(uint _id) public view returns(Gift memory){
        
        for(uint i=0; i < gifts.length; i++) {
            if(gifts[i].id == _id)
                return gifts[i];
        }
        
        revert("Not found");
    }
    
    function claimGift(string memory _pass)  public returns(string memory) {
        for(uint i=0; i < gifts.length; i++) {
            Gift memory gift = gifts[i];
            
            bool found = false;
            if(gift.claimer  == msg.sender)
                found = true;
            
            require(!found, "Claimer not registered");
            
            if(keccak256(abi.encodePacked((gift.pass))) == keccak256(abi.encodePacked((_pass)))) {
                
                if(gift.am > 0) {
                    
                    require(gift.am < address(this).balance, "Not enough funds");
                    payable(msg.sender).transfer(gift.am);
                    delete gifts[i];
                    return string(abi.encodePacked("Congrats, check your wallet", gift.data));
                    
                } else {
                    delete gifts[i];
                    return string(abi.encodePacked("Claim your gift from ", gift.data));
                }
                
            }
                
        }
        
        return "Invalid request";
    }
    
    function getTarget() public view returns (string memory){
        return target;
    }
    
     function getBalance() public view returns (uint256){
        return address(this).balance;
    }
}