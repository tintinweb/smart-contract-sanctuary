/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

pragma solidity ^0.8.0;


// THIS IS THE BASTARD GAN PUNKS V2 PROXY SALE CONTRACT: 

// THE CONTRACT IS WRITTEN TO CATAPULT A NEW PRICING MODEL TO KILL THE BONDING CURVE ON ORIGINAL CONTRACT, TO GIVE NEW MINTS TO USERS VIA DISCOUNTED PRICE. AND ALL INCOME FROM MINTS DIRECTLY GO TO CHARITIES OF MINTER'S CHOICE. 

// LONG LIVE BASTARDS! 

// WHAT THIS CONTRACT BASICALLY DOES IS: 

// THE PRICE GRADUALLY DECREASES EVERY SECOND, AND WHEN SOMEONE ADOPTS A BASTARD FROM HERE, FEE IS DIRECTLY TRANSFERRED TO CHARITY, AND THIS CONTRACT ADOPTS A BASTARD FROM ORIGINAL CONTRACT WITH ORIGINAL PRICE, AND TRANSFERS TO THE MINTER.

// Project website: https://bastardganpunks.club

// berk aka PrincessCamel - https://berkozdemir.com

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

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface BGANPUNKSV2 {
    function calculatePrice() external view returns (uint256);

    function adoptBASTARD(uint256 numBastards) external payable;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function totalSupply() external view returns (uint256);
}

// THIS IS WHERE THE MAGIC HAPPENS

contract BASTARDGANPUNKSV2PROXYSALE is Ownable, IERC721Receiver {

    address payable public treasuryAddress;

    uint256 public startTime;
    bool public saleRunning = false;

    uint256 private two = 2;
    uint256 public startprice; 
    uint256 public discountPerSecond;
    uint256 public halvingTimeInterval;

    address public BGANPUNKSV2ADDRESS =
        0x31385d3520bCED94f77AaE104b406994D8F2168C;

    struct Charity {
        string name;
        address charityAddress;
    }

    Charity[] public charities;
    
    event saleStarted( uint indexed startTime, uint indexed startPrice, uint indexed halvingTimeInterval);
    event charityAdded(string indexed _name, address indexed _address);
    event charityEdited(uint indexed _index, string indexed _name, address indexed _address);
    event charityRemoved(uint indexed _index);
    event donationSent(string indexed charityName, uint indexed amount);

    constructor(address payable _treasuryAddress) {
        treasuryAddress = _treasuryAddress;
    }

    receive() external payable {}

    function startSale(uint256 _startPrice, uint256 _halvingInterval)
        public
        onlyOwner
    {
        startTime = block.timestamp;
        startprice = _startPrice;
        halvingTimeInterval = _halvingInterval;
        discountPerSecond = startprice / halvingTimeInterval / two;
        saleRunning = true;
        emit saleStarted(startTime, _startPrice, _halvingInterval);
    }

    function pauseSale() public onlyOwner {
        saleRunning = false;
    }
    function resumeSale() public onlyOwner {
        saleRunning = true;
    }

    // SET CHARITIES AND VIEW

    function addCharity(address _address, string memory _name)
        public
        onlyOwner
    {
        charities.push(Charity(_name, _address));
        emit charityAdded(_name, _address);
    }
    
    
    function editCharity(
        uint256 index,
        address _address,
        string memory _name
    ) public onlyOwner {
        charities[index].name = _name;
        charities[index].charityAddress = _address;
        emit charityEdited(index, _name, _address);

    }


    function removeCharityNoOrder(uint index)
        public
        onlyOwner
    {
        charities[index] = charities[charities.length - 1];
        charities.pop();
        emit charityRemoved(index);
    }

    function getCharityCount() public view returns (uint256) {
        return charities.length;
    }

    function getCharities() public view returns (Charity[] memory) {
        return charities;
    }
    
    function getCharity(uint index) public view returns (Charity memory) {
        require(index < charities.length, "YOU REQUESTED A CHARITY OUTSIDE THE RANGE PAL");
        return charities[index];
    }

    // MINTING BASTARDS - CALCULATING PRICE AND TIME

    function howManySecondsElapsed() public view returns (uint256) {
        if(saleRunning) {
        return block.timestamp - startTime;
        } else {
            return 0;
        }
    }

    function calculateDiscountedPrice() public view returns (uint256) {
        require(saleRunning, "SALE HASN'T STARTED OR PAUSED");

        uint256 elapsed = block.timestamp - startTime;
        uint256 factorpow = elapsed / halvingTimeInterval;
        uint256 priceFactor = two ** factorpow;

        uint256 howmanyseconds =
            elapsed % halvingTimeInterval * discountPerSecond / priceFactor;

        uint256 finalPrice = startprice / priceFactor - howmanyseconds;
        return finalPrice;
    }

    function calculateDiscountedPriceTest(uint256 elapsedTime)
        public
        view
        returns (uint256)
    {
        require(saleRunning, "SALE HASN'T STARTED OR PAUSED");
        uint256 factorpow = elapsedTime / halvingTimeInterval;
        uint256 priceFactor = two**factorpow;

        uint256 howmanyseconds =
            elapsedTime % halvingTimeInterval * discountPerSecond / priceFactor;

        uint256 finalPrice = startprice / priceFactor - howmanyseconds;
        return finalPrice;
    }

    function adoptCheaperBASTARD(uint256 _charitychoice, uint256 _amount)
        public
        payable
    {
        uint256 originalPrice =
            BGANPUNKSV2(BGANPUNKSV2ADDRESS).calculatePrice() * _amount;

        require(
            msg.value >= calculateDiscountedPrice() * _amount,
            "YOU HAVEN'T PAID ENOUGH LOL"
        );
        require(
            _charitychoice < charities.length,
            "U CHOSE A CHARITY THAT DOESN'T EXIST"
        );

        payable(charities[_charitychoice].charityAddress).transfer(msg.value);

        BGANPUNKSV2(BGANPUNKSV2ADDRESS).adoptBASTARD{value: originalPrice}(
            _amount
        );
        uint256 total = BGANPUNKSV2(BGANPUNKSV2ADDRESS).totalSupply();
        for (uint256 i = total - _amount; i < total; i++) {
            BGANPUNKSV2(BGANPUNKSV2ADDRESS).safeTransferFrom(
                address(this),
                msg.sender,
                i,
                ""
            );
        }
        emit donationSent(charities[_charitychoice].name, msg.value);
    }

    // ADD - REMOVE FUNDS TO MAKE THIS CONTRACT ABLE TO BUY BASTARDS FROM THE ORIGINAL BGANPUNKSV2 CONTRACT

    function addFundsToContract() public payable onlyOwner {
        payable(address(this)).transfer(msg.value);
    }

    function returnFunds() public onlyOwner {
        treasuryAddress.transfer(address(this).balance);
    }

    function setTreasuryAddress(address payable _address) public onlyOwner {
        treasuryAddress = _address;
    }

    // SOME BORING STUFF THAT IS NEEDED

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}