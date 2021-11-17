// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface ERC721{
    function batchMint(address to, uint256 numberOfNFTs) external;
}

interface ERC20{
    function decimals() external view returns(uint256);
    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
}

contract RevogPrimaryMarketplace is Ownable, ReentrancyGuard{

//VARIABLES

    uint256 private constant BASE_DECIMAL = 18;
    uint256 private constant DENOMINATOR = 10000;
    
    uint256 public maxBuyAllowed;
     
    mapping(address => bool) public supportedPriceTokens;
    address[] internal supportedPriceTokensInternal;
  
    struct Sale {
        address buyer;
        uint256 boughtAt;
        uint256 price;
        uint256 fees;
        uint256 feesAmount;
        uint256 totalUnits;
        address priceToken;
    }
    mapping(address => mapping(uint256 => Sale)) public sales;
    
    struct FeesDetail {
        bool status;
        mapping(address => uint256) collectedPerToken;
        mapping(address => uint256) withdrawalPerToken;
    }
    FeesDetail private feesDetail;
    uint256 public fees;
    
    struct ContractDetails {
        bool isWhitelisted;
        uint256 price;
        mapping(address => uint256) volumePerToken;
        mapping(address => uint256) feesPerToken;
        uint256 totalUnitsSold;
        uint256 totalSale;
        uint256 statusUpdatedAt;
        address priceToken;
        address author;
        uint256 saleStartTime;
    }
    mapping(address => ContractDetails) public whitelistedContracts;
    address[] private whitelistedContractsInternal;
   
//EVENTS
    event PriceDetailsChanged(address nftContract, address changedBy, uint256 changedAt, uint256 newPrice, address priceTokendId);
    event AuthorChanged(address newAuthor, address nftContract, address changedBy, uint256 changedAt);
    event Buy(address nftContract, address buyer, uint256 boughtAt, uint256 price, uint256 totalUnits, uint256 fees, address priceToken);
    event maxBuyAllowedChaned(uint256 newMaxBuyAllowed, address changedBy, uint256 changedAt);
    event WhitelistedContract(address nftContract, address author, uint256 price, address priceTokend, address whitestedBy, uint256 whitelistedAt, uint256 saleStartTime);
    event BlacklistedContract(address nftContract, address whitestedBy, uint256 blacklistedAt);
    event PriceTokenAdded(address priceToken, address addedBy, uint256 addedAt);
    event PriceTokenDisabled(address priceToken, address disabledBy, uint256 disabledAt);
    event FeesChanged(uint256 newFees, address changedBy, uint256 changedAt);
    event FeesWithdrawal(address priceToken, uint256 amount, address withdrawalBy, uint256 withdrawalAt);
    
    constructor(uint256 _maxBuyAllowed, uint256 _fees){
        maxBuyAllowed = _maxBuyAllowed;
        supportedPriceTokens[address(0)] = true;
        supportedPriceTokensInternal.push(address(0));
        fees = _fees;
        emit PriceTokenAdded(address(0), msg.sender, block.timestamp);
        emit FeesChanged(_fees, msg.sender, block.timestamp);
        emit maxBuyAllowedChaned(_maxBuyAllowed, msg.sender, block.timestamp);
    }

//USER FUNCTIONS
    function buy(address _nftContract, uint256 _totalUnits) external nonReentrant() payable returns(bool){
        require(_totalUnits <= maxBuyAllowed, 'Invalid number of units' );
        ContractDetails storage contractDetails = whitelistedContracts[_nftContract];
        require(contractDetails.isWhitelisted, 'NFT contract is not whitelisted!!');
        require(contractDetails.saleStartTime <= block.timestamp, 'Sale not yet started');
        address priceToken = contractDetails.priceToken;
        uint256 totalPrice = _totalUnits * contractDetails.price;
        uint256 feesAmount = totalPrice * fees / DENOMINATOR;
     
        contractDetails.volumePerToken[priceToken] = contractDetails.volumePerToken[priceToken] + totalPrice;
        contractDetails.feesPerToken[priceToken] = contractDetails.feesPerToken[priceToken] + feesAmount;
        contractDetails.totalUnitsSold = contractDetails.totalUnitsSold + _totalUnits;
        contractDetails.totalSale = contractDetails.totalSale + 1;
        
        Sale storage sale = sales[_nftContract][ contractDetails.totalSale];
        sale.price = contractDetails.price;
        sale.priceToken = priceToken;
        sale.boughtAt = block.timestamp;
        sale.buyer = msg.sender;
        sale.totalUnits = _totalUnits;
        sale.fees = fees;
        sale.feesAmount = feesAmount;
    
        feesDetail.collectedPerToken[priceToken] = feesDetail.collectedPerToken[priceToken] + feesAmount;
     
        if(priceToken== address(0)){
            require(msg.value >= totalPrice, 'amount paid is less than the total price of NFTs');
            uint256 extraAmountPaid = msg.value - totalPrice;
            payable(whitelistedContracts[_nftContract].author).transfer(totalPrice - feesAmount);
            if(extraAmountPaid > 0){
                payable(msg.sender).transfer(extraAmountPaid);
            }
        }else {
            ERC20(priceToken).transferFrom(msg.sender, address(this), convertValue(totalPrice, priceToken, false));
            ERC20(priceToken).transfer(whitelistedContracts[_nftContract].author, convertValue(totalPrice - feesAmount, priceToken, false));
        }
     
        ERC721(_nftContract).batchMint(msg.sender, _totalUnits);
        emit Buy(_nftContract, msg.sender, block.timestamp, totalPrice, _totalUnits, fees, priceToken);
        return true;
    }
  
//OWNER FUNCTIONS

    function whitelistContract(address _nftContract, address _author, uint256 _price, address _priceToken, uint256 _saleStartTime) external onlyOwner() returns(bool){
        require(_nftContract != address(0), 'Invalid contract address');
        require(_author != address(0), 'Invalid author');
        require(supportedPriceTokens[_priceToken], 'Price token not supported');
        require(!whitelistedContracts[_nftContract].isWhitelisted, 'Already whitelisred');
        if(whitelistedContracts[_nftContract].author == address(0)){
            whitelistedContractsInternal.push(_nftContract);
        }
        whitelistedContracts[_nftContract].price = convertValue(_price, _priceToken, true);
        whitelistedContracts[_nftContract].priceToken = _priceToken;
        whitelistedContracts[_nftContract].isWhitelisted = true;
        whitelistedContracts[_nftContract].author = _author;
        whitelistedContracts[_nftContract].statusUpdatedAt = block.timestamp;
        whitelistedContracts[_nftContract].saleStartTime = _saleStartTime;
        emit WhitelistedContract(_nftContract, _author, whitelistedContracts[_nftContract].price, _priceToken, msg.sender, block.timestamp, _saleStartTime);
        return true;
    }
    
    function updatePriceDetails(address _nftContract, uint256 _newPrice, address _newPriceToken) external onlyOwner() returns(bool){
        ContractDetails storage contractDetails = whitelistedContracts[_nftContract];
        require(contractDetails.isWhitelisted, 'NFT contract is not whitelisted!!');
        require(supportedPriceTokens[_newPriceToken], 'Price token not supported');
        contractDetails.price = convertValue(_newPrice, _newPriceToken, true) ;
        contractDetails.priceToken = _newPriceToken;
        emit PriceDetailsChanged(_nftContract, msg.sender, block.timestamp, _newPrice, _newPriceToken);
        return true;
    }
    
    function updateAuthor(address _nftContract, address _newAuthor) external onlyOwner() returns(bool){
        ContractDetails storage contractDetails = whitelistedContracts[_nftContract];
        require(contractDetails.isWhitelisted, 'NFT contract not whitelisted!!');
        require(_newAuthor != address(0), 'Invalid author');
        contractDetails.author = _newAuthor;
        emit AuthorChanged( _newAuthor, _nftContract, msg.sender, block.timestamp);
        return true;
    }
 
    function blacklistContract(address _nftContract) external onlyOwner() returns(bool){
        require(whitelistedContracts[_nftContract].isWhitelisted, 'Invalid contract');
        whitelistedContracts[_nftContract].isWhitelisted = false;
        whitelistedContracts[_nftContract].statusUpdatedAt = block.timestamp;
        emit BlacklistedContract(_nftContract, msg.sender, block.timestamp);
        return true;
    }
    
    function updateMaxBuyAllowed(uint256 _maxBuyAllowed) external onlyOwner() returns(bool){
        require(_maxBuyAllowed > 0, 'Max buy Allowed can not be zero');
        maxBuyAllowed = _maxBuyAllowed;
        emit maxBuyAllowedChaned(maxBuyAllowed, msg.sender, block.timestamp);
        return true;
    }

    function addPriceToken(address _newPriceToken) external onlyOwner() returns(bool){
        require(_newPriceToken != address(0), 'Invalid address');
        require(!supportedPriceTokens[_newPriceToken], 'Already added');
        supportedPriceTokens[_newPriceToken] = true;
        bool isPriceTokenExist = priceTokenExist(_newPriceToken);
        if(!isPriceTokenExist){
            supportedPriceTokensInternal.push(_newPriceToken);
        }
        emit PriceTokenAdded(_newPriceToken, msg.sender, block.timestamp);
        return true;
    }
    
    function disablePriceToken(address _priceToken) external onlyOwner() returns(bool){
        require(!supportedPriceTokens[_priceToken], 'Invalid price token');
        supportedPriceTokens[_priceToken] = false;
        emit PriceTokenDisabled(_priceToken, msg.sender, block.timestamp);
        return true;
    }
    
    function withdrawFees(address _priceToken) external onlyOwner() nonReentrant() returns(bool){
        uint256 availableFees = feesDetail.collectedPerToken[_priceToken] - feesDetail.withdrawalPerToken[_priceToken];
        require(availableFees > 0, 'Nothing to withdraw for this token');
        feesDetail.withdrawalPerToken[_priceToken] = feesDetail.withdrawalPerToken[_priceToken] + availableFees;
        if(_priceToken == address(0)){
            payable(msg.sender).transfer(availableFees);
        } else {
            ERC20(_priceToken).transfer(msg.sender, convertValue(availableFees, _priceToken, false));
        }
        emit FeesWithdrawal(_priceToken, availableFees, msg.sender, block.timestamp);
        return true;
    }
    
    function updateFees(uint256 _newFees) external onlyOwner() returns(bool){
        fees = _newFees;
        emit FeesChanged( _newFees, msg.sender, block.timestamp);
        return true;
    }
 
//VIEW FUNCTIONS
    function priceTokensList() external view returns(address[] memory){
        return supportedPriceTokensInternal;
    }

    function getNFTContracts() external view returns(address[] memory){
        return whitelistedContractsInternal;
    }

    function getFeesDetails(address _priceToken) external view returns(uint256, uint256){
        return (feesDetail.collectedPerToken[_priceToken], feesDetail.withdrawalPerToken[_priceToken]);
    }

    function getNFTContractPriceDetails(address _nftContract, address _priceToken) external view returns(uint256, uint256){
        return (whitelistedContracts[_nftContract].volumePerToken[_priceToken], whitelistedContracts[_nftContract].feesPerToken[_priceToken]);
    }

    
    
//INTERNAL FUNCTIONS
    receive() payable external{
        
    }
    
    function convertValue(uint256 _value, address _priceToken, bool _toBase) internal view returns(uint256){
        if(_priceToken == address(0) || ERC20(_priceToken).decimals() == BASE_DECIMAL){
            return _value;
        }
        uint256 decimals = ERC20(_priceToken).decimals();
        if(_toBase){
            return _value * 10**(BASE_DECIMAL - decimals);
        } else {
            return _value / 10**(BASE_DECIMAL - decimals);
        }
    }
        
    function priceTokenExist(address _priceToken) internal view returns(bool){
        for(uint index = 0; index < supportedPriceTokensInternal.length; index++){
            if(supportedPriceTokensInternal[index] == _priceToken){
                return true;
            }
        }
        return false;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
        return msg.data;
    }
}