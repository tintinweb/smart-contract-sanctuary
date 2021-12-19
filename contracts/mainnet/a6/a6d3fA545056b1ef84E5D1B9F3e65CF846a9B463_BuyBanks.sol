// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*


▄▄▄█████▓ ██░ ██ ▓█████     ██░ ██ ▓█████  ██▓  ██████ ▄▄▄█████▓
▓  ██▒ ▓▒▓██░ ██▒▓█   ▀    ▓██░ ██▒▓█   ▀ ▓██▒▒██    ▒ ▓  ██▒ ▓▒
▒ ▓██░ ▒░▒██▀▀██░▒███      ▒██▀▀██░▒███   ▒██▒░ ▓██▄   ▒ ▓██░ ▒░
░ ▓██▓ ░ ░▓█ ░██ ▒▓█  ▄    ░▓█ ░██ ▒▓█  ▄ ░██░  ▒   ██▒░ ▓██▓ ░ 
  ▒██▒ ░ ░▓█▒░██▓░▒████▒   ░▓█▒░██▓░▒████▒░██░▒██████▒▒  ▒██▒ ░ 
  ▒ ░░    ▒ ░░▒░▒░░ ▒░ ░    ▒ ░░▒░▒░░ ▒░ ░░▓  ▒ ▒▓▒ ▒ ░  ▒ ░░   
    ░     ▒ ░▒░ ░ ░ ░  ░    ▒ ░▒░ ░ ░ ░  ░ ▒ ░░ ░▒  ░ ░    ░    
  ░       ░  ░░ ░   ░       ░  ░░ ░   ░    ▒ ░░  ░  ░    ░      
          ░  ░  ░   ░  ░    ░  ░  ░   ░  ░ ░        ░           
                                                                

            ;`.                       ,'/
            |`.`-.      _____      ,-;,'|
            |  `-.\__,-'     `-.__//'   |
            |     `|               \ ,  |
            `.  ```                 ,  .'
              \_`      \     /      `_/
                \    ^  \   /   ^   /
                 |   X   ____   X  |
                 |     ,'    `.    |
                 |    (  O' O  )   |
                 `.    \__,.__/   ,'
                   `-._  `--'  _,'
                       `------'

created with curiosity by .pwa group 2021.

    gm. wgmi.

            if you're reading this, you are early.

*/

import "../Interfaces/I_TokenBank.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "../Models/Base/Pausable.sol";
import "../Models/PaymentHandler.sol";

contract BuyBanks is Ownable, Pausable, PaymentHandler {

    uint256 public constant MAX_ETH_MINTABLE = 1250;
    uint256 public constant MINTS_PER_TRANSACTION = 3;
    uint256 totalMinted;

    uint256 constant MAX_GIFT = 10;
    uint256 totalGifted;

    I_TokenBank tokenBank;

    constructor(address _tokenBankAddress) {
        tokenBank = I_TokenBank(_tokenBankAddress);
    }

    function GetPrice() public view returns (uint256)
    {        
        if(totalMinted <= 500) {
            return 0.2 ether; }
        else if(totalMinted > 500 && totalMinted <= 800) {
            return 0.5 ether; }
        else if(totalMinted > 800 && totalMinted <= 1000) {
            return 0.7 ether; }
        else if(totalMinted > 1000 && totalMinted <= 1150) {
            return 0.8 ether; }
        else {
            return 1 ether; //more than 1150
        }
    } 

    function Buy(uint256 amountToBuy) external payable whenNotPaused {

        uint256 _ethPrice = GetPrice();

        require(msg.value >= _ethPrice * amountToBuy,"Not enough ETH"); //n.b. slight discount on price boundaries with volume
        require(amountToBuy <= MINTS_PER_TRANSACTION,"Too many per transaction");
                
        require(totalMinted + amountToBuy <= MAX_ETH_MINTABLE,"Sold out");

        uint256 newTotalMinted = totalMinted;
        for (uint256 i = 0; i < amountToBuy; i++ ){
            newTotalMinted += 1;
            tokenBank.Mint(1, msg.sender);
        }
        totalMinted = newTotalMinted;
    }

    function Gift(uint256 amountToGift, address to) external onlyOwner {
        require(totalGifted + amountToGift <= MAX_GIFT,"No more characters left");

        uint256 newTotalGifted = totalGifted;

        for (uint256 i = 0; i < amountToGift; i++ ){
            newTotalGifted += 1;
            tokenBank.Mint(1, to);
        }

        totalGifted = newTotalGifted;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//Interface for Bank NFT
interface I_TokenBank {

    function Mint(uint8, address) external; //amount, to
    
    function totalSupply() external view returns (uint256);
    function setApprovalForAll(address, bool) external;  //address, operator
    function transferFrom(address, address, uint256) external;
    function ownerOf(uint256) external view returns (address); //who owns this token
    function _ownerOf16(uint16) external view returns (address);

    function addController(address) external;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";


//allows pausing of critical functions in the contract
contract Pausable is Ownable {

    bool public paused = false; //start unpaused

    event Paused();
    event Unpaused();

    modifier whenNotPaused() {
        require(!paused,"Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused,"Contract is not paused");
        _;
    }

    function Pause() onlyOwner whenNotPaused external {
        paused = true;
        emit Paused();
    }

    function Unpause() onlyOwner whenPaused external {
        paused = false;
        emit Unpaused();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

//simple payments handling for splitting between a wallet and contract owner
contract PaymentHandler is Ownable{

    address otherWallet;

    function setWithdrawWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0));
        otherWallet = newWallet;
    }

    //payments
    function withdrawAll() external onlyOwner {
        require(otherWallet != address(0),"Withdraw wallet not set");
                
        payable(otherWallet).transfer(address(this).balance / 2); //50%
        payable(owner()).transfer(address(this).balance); //50%        
    }

    function withdrawAmount(uint amount) external onlyOwner {
        require(otherWallet != address(0),"Withdraw wallet not set");
        require(address(this).balance >= amount);

        payable(otherWallet).transfer(amount / 2); //50%
        payable(owner()).transfer(amount / 2); //50%     
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