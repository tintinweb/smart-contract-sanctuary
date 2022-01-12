// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";

/*        _____                    _____                    _____          
         /\    \                  /\    \                  /\    \         
        /::\    \                /::\    \                /::\____\        
       /::::\    \              /::::\    \              /:::/    /        
      /::::::\    \            /::::::\    \            /:::/   _/___      
     /:::/\:::\    \          /:::/\:::\    \          /:::/   /\    \     
    /:::/__\:::\    \        /:::/__\:::\    \        /:::/   /::\____\    
   /::::\   \:::\    \      /::::\   \:::\    \      /:::/   /:::/    /    
  /::::::\   \:::\    \    /::::::\   \:::\    \    /:::/   /:::/   _/___  
 /:::/\:::\   \:::\    \  /:::/\:::\   \:::\    \  /:::/___/:::/   /\    \ 
/:::/  \:::\   \:::\____\/:::/__\:::\   \:::\____\|:::|   /:::/   /::\____\
\::/    \:::\   \::/    /\:::\   \:::\   \::/    /|:::|__/:::/   /:::/    /
 \/____/ \:::\   \/____/  \:::\   \:::\   \/____/  \:::\/:::/   /:::/    / 
          \:::\    \       \:::\   \:::\    \       \::::::/   /:::/    /  
           \:::\____\       \:::\   \:::\____\       \::::/___/:::/    /   
            \::/    /        \:::\   \::/    /        \:::\__/:::/    /    
             \/____/          \:::\   \/____/          \::::::::/    /     
                               \:::\    \               \::::::/    /      
                                \:::\____\               \::::/    /       
                                 \::/    /                \::/____/        
                                  \/____/                  ~~              */

contract Fewwwww is Ownable {
    string public NAME_PROJECT = "Fewwwww";
    string public CREATED_BY = "0xBosz";
    uint256 public PREMIUM_PRICE = 0.1 ether;
    uint256 public PERCENT_FEE = 0;

    uint256 public premiumUsers;
    mapping(address => bool) public _premiumList;

    function sendEthers(address payable [] memory _receiver) public payable {
        for(uint256 i = 0; i < _receiver.length; i++) {
            uint256 amount = msg.value / _receiver.length;
            require(_receiver[i] != address(0), "Cannot transfer to null address");

            if (_premiumList[msg.sender]) {
                _receiver[i].transfer(amount);
            } else {
                _receiver[i].transfer(amount - (amount * PERCENT_FEE) / 1000);
            }
        }
    }

    function purchasePremium() public payable {
        require(!_premiumList[msg.sender], "You already on premium list");
        require(msg.value == PREMIUM_PRICE, "Ether value sent incorrect");

        _premiumList[msg.sender] = true;
        premiumUsers++;
    }

    function donation() public payable {
        require(msg.value > 0, "Ether value sent should not 0 eth");

     /* ████████╗██╗░░██╗░█████╗░███╗░░██╗██╗░░██╗░██████╗
        ╚══██╔══╝██║░░██║██╔══██╗████╗░██║██║░██╔╝██╔════╝
        ░░░██║░░░███████║███████║██╔██╗██║█████═╝░╚█████╗░
        ░░░██║░░░██╔══██║██╔══██║██║╚████║██╔═██╗░░╚═══██╗
        ░░░██║░░░██║░░██║██║░░██║██║░╚███║██║░╚██╗██████╔╝
        ░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝╚═╝░░╚═╝╚═════╝░

        ███████╗░█████╗░██████╗░
        ██╔════╝██╔══██╗██╔══██╗
        █████╗░░██║░░██║██████╔╝
        ██╔══╝░░██║░░██║██╔══██╗
        ██║░░░░░╚█████╔╝██║░░██║
        ╚═╝░░░░░░╚════╝░╚═╝░░╚═╝

        ░██████╗██╗░░░██╗██████╗░██████╗░░█████╗░██████╗░████████╗░░░
        ██╔════╝██║░░░██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝░░░
        ╚█████╗░██║░░░██║██████╔╝██████╔╝██║░░██║██████╔╝░░░██║░░░░░░
        ░╚═══██╗██║░░░██║██╔═══╝░██╔═══╝░██║░░██║██╔══██╗░░░██║░░░░░░
        ██████╔╝╚██████╔╝██║░░░░░██║░░░░░╚█████╔╝██║░░██║░░░██║░░░██╗
        ╚═════╝░░╚═════╝░╚═╝░░░░░╚═╝░░░░░░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝ */

    }

    function changePrice(uint256 _newPrice) public onlyOwner {
        PREMIUM_PRICE = _newPrice;
    }

    function setPercentFee(uint256 _percentageFee) public onlyOwner {
        PERCENT_FEE = _percentageFee;
    }

    function addPremiumUsers(address[] memory _address) public onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            _premiumList[_address[i]] = true;
            premiumUsers++;
        }
    }

    function withdraw() public onlyOwner {
        uint amount = address(this).balance;
        (bool success,) = owner().call{value: amount}("");
        require(success, "Failed to send ether");
    }

    // 0x0000000000000000000000000000000000000000
    function kill(address payable _receiver) public payable onlyOwner {
        selfdestruct(_receiver);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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