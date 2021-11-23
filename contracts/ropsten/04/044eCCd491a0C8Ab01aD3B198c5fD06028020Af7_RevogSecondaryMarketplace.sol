// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface ERC721{
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface ERC20{
    function decimals() external view returns(uint256);
    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
}

contract RevogSecondaryMarketplace is Ownable, ReentrancyGuard{

//VARIABLES

    uint256 private constant DENOMINATOR = 10000;
    uint256 private constant BASE_DECIMAL = 18;
    uint256 public fees;   
    
    enum Status{ Sold, UnSold, Removed } 
    struct Sale {
        address seller;
        address buyer;
        uint256 nftId;
        uint256 listedAt;
        uint256 price;
        uint256 fees;
        uint256 authorFees;
        address priceToken;
        Status status;
    }
    //nftContract => saleId
    mapping(address => mapping(uint256 => Sale)) public sales;
    
    struct FeesDetail {
        bool status;
        mapping(address => uint256) collectedPerToken;
        mapping(address => uint256) withdrawalPerToken;
    }
    FeesDetail private feesDetail;
    
    struct ContractDetails {
        bool isWhitelisted;
        address author;
        uint256 authorFees;
        mapping(address => uint256) volumePerToken;
        mapping(address => uint256) feesPerToken;
        uint256 totalSold;
        uint256 totalListed;
        uint256 totalRemoved;
    }
    mapping(address => ContractDetails) public whitelistedContracts;
    address[] private whitelistedContractsInternal;
    
    struct SaleIdDetail {
        uint256[] allSaleIds;
        uint256 currentSaleId;
    }
    mapping(address => mapping(uint256 => SaleIdDetail)) public nftSaleIds;
    
    mapping(address => bool) public supportedPriceTokens;
    address[] internal supportedPriceTokensInternal;
    
//EVENTS
    event FeesChanged(uint256 newFee, address changedBy, uint256 time);
    event AddedToMarketplace(address nftContract, uint256 nftId, address seller, uint256 listedAt, uint256 price, uint256 fees, uint256 authorFees, uint256 saleId, address priceToken);
    event Buy(address nftContract, address buyer, uint256 saleId, uint256 boughtAt);
    event RemovedFromMarketplace(address nftContract, uint256 saleId);
    event PriceUpdated(address nftContract, uint256 saleId, uint256 price, address priceToken);
    event PriceTokenAdded(address priceToken, address addedBy, uint256 addedAt);
    event PriceTokenDisabled(address priceToken, address disabledBy, uint256 disabledAt);
    event WhitelistedContract(address nftContract, address author, uint256 authorFees, address whitelistedBy, uint256 whitelistedAt);
    event AuthorDetailsChanged(address nftContract, address author, uint256 authorFees, address changedBy, uint256 changedAt);
    event BlacklistedContract(address nftContract, address blacklistedBy, uint256 blacklistedAt);
    event FeesWithdrawal(address priceToken, uint256 amount, address withdrawalBy, uint256 withdrawalAt);
    
//CONSTRUCTOR
    constructor(uint256 _fees){
        require(fees <= DENOMINATOR, 'INVALID FEES');
        fees = _fees;
        supportedPriceTokens[address(0)] = true;
        supportedPriceTokensInternal.push(address(0));
        emit PriceTokenAdded(address(0), msg.sender, block.timestamp);
        emit FeesChanged(_fees, msg.sender, block.timestamp);
    }
    
//USER FUNCTIONS
    function addToMarketplace(address _nftContract, uint256 _nftId, uint256 _price, address _priceToken) external nonReentrant() returns(bool){
        require(supportedPriceTokens[_priceToken], 'Price token not supported');
        ContractDetails storage contractDetails = whitelistedContracts[_nftContract];
        require(contractDetails.isWhitelisted, 'NFT contract not whitelisted!!');
        uint256 currentSaleId = nftSaleIds[_nftContract][_nftId].currentSaleId;
        require(currentSaleId == 0, 'Already listed');
        uint256 saleId = contractDetails.totalListed + 1;
        Sale storage sale = sales[_nftContract][saleId];
        sale.nftId = _nftId;
        sale.seller = msg.sender;
        sale.listedAt = block.timestamp;
        sale.price = convertValue(_price, _priceToken, true);
        sale.fees = fees;
        sale.authorFees = contractDetails.authorFees;
        sale.priceToken = _priceToken;
        sale.status = Status.UnSold;
        nftSaleIds[_nftContract][_nftId].allSaleIds.push(saleId);
        nftSaleIds[_nftContract][_nftId].currentSaleId = saleId;
        contractDetails.totalListed = contractDetails.totalListed + 1;
        ERC721(_nftContract).transferFrom(msg.sender, address(this), _nftId);
        emit AddedToMarketplace(_nftContract, _nftId, msg.sender, sale.listedAt, sale.price, fees, contractDetails.authorFees, saleId, _priceToken);
        return true;
    }
    
    function removeFromMarketplace(address _nftContract, uint256 _nftId) external nonReentrant() returns(bool){
        uint256 saleId = nftSaleIds[_nftContract][_nftId].currentSaleId;
        require(saleId > 0, 'This NFT is not listed');
        Sale storage sale = sales[_nftContract][saleId];
        require(sale.seller == msg.sender, 'Only seller can remove');
        sale.status = Status.Removed;
        nftSaleIds[_nftContract][_nftId].currentSaleId = 0;
        whitelistedContracts[_nftContract].totalRemoved = whitelistedContracts[_nftContract].totalRemoved + 1;
        ERC721(_nftContract).transferFrom(address(this), sale.seller, _nftId);
        emit RemovedFromMarketplace(_nftContract, saleId);
        return true;
    }
    
    function buy(address _nftContract, uint256 _nftId) external nonReentrant() payable returns(bool){
        uint256 saleId = nftSaleIds[_nftContract][_nftId].currentSaleId;
        require(saleId > 0, 'This NFT is not listed');
        Sale storage sale = sales[_nftContract][saleId];
        ContractDetails storage contractDetails = whitelistedContracts[_nftContract];
        
        sale.status = Status.Sold;
        sale.buyer = msg.sender;

        nftSaleIds[_nftContract][_nftId].currentSaleId = 0;
        uint256 authorShare = sale.price * sale.authorFees / DENOMINATOR;
        uint256 marketPlaceFees = sale.price * sale.fees / DENOMINATOR;
        address priceToken = sale.priceToken;

        feesDetail.collectedPerToken[priceToken] = feesDetail.collectedPerToken[priceToken] + marketPlaceFees;
    
        contractDetails.volumePerToken[priceToken] = contractDetails.volumePerToken[priceToken] + sale.price;
        contractDetails.feesPerToken[priceToken] = contractDetails.feesPerToken[priceToken] + marketPlaceFees;
        contractDetails.totalSold = contractDetails.totalSold + 1;
      
        if(priceToken == address(0)){
            require(msg.value >= sale.price, 'amount paid is less than the price of NFT');
            uint256 extraAmountPaid = msg.value - sale.price;
            payable(sale.seller).transfer(sale.price - authorShare - marketPlaceFees);
            payable(contractDetails.author).transfer(authorShare);
            if(extraAmountPaid > 0){
                payable(msg.sender).transfer(extraAmountPaid);
            }
        } else {
            ERC20(priceToken).transferFrom(msg.sender, address(this), convertValue(sale.price, priceToken, false));
            ERC20(priceToken).transfer(contractDetails.author, convertValue(authorShare, priceToken, false));
            ERC20(priceToken).transfer(sale.seller, convertValue(sale.price - authorShare - marketPlaceFees, priceToken, false));
        }
        ERC721(_nftContract).transferFrom(address(this), msg.sender, _nftId);
        emit Buy(_nftContract, msg.sender, saleId, block.timestamp);
        return true;
    }
    
    function updatePrice(address _nftContract, uint256 _nftId, uint256 _newPrice, address _priceToken) external returns(bool){
        require(supportedPriceTokens[_priceToken], 'Price token not supported');
        uint256 saleId = nftSaleIds[_nftContract][_nftId].currentSaleId;
        require(saleId > 0, 'This NFT is not listed');
        Sale storage sale = sales[_nftContract][saleId];
        require(sale.seller == msg.sender, 'Only seller can update price');
        sale.priceToken = _priceToken;
        sale.price = convertValue(_newPrice, _priceToken, true);
        emit PriceUpdated(_nftContract, saleId, sale.price, _priceToken);
        return true;
    }
  
//OWNER FUNCTIONS

    function whitelistContract(address _nftContract, address _author, uint256 _authorFees) external onlyOwner() returns(bool){
        require(!whitelistedContracts[_nftContract].isWhitelisted, 'Already whitelisted');
        require(_nftContract != address(0), 'Invalid contract address');
        require(_author != address(0), 'Invalid author');
        require(_authorFees + fees <= DENOMINATOR, 'Invalid author fees');
        if(whitelistedContracts[_nftContract].author == address(0)){
            whitelistedContractsInternal.push(_nftContract);
        }
        whitelistedContracts[_nftContract].author = _author;
        whitelistedContracts[_nftContract].authorFees = _authorFees;
        whitelistedContracts[_nftContract].isWhitelisted = true;
        emit WhitelistedContract(_nftContract, _author, _authorFees, msg.sender, block.timestamp);
        return true;
    }
    
    function changeAuthorDetails(address _nftContract, address _author, uint256 _authorFees) external onlyOwner() returns(bool){
        require(whitelistedContracts[_nftContract].isWhitelisted, 'Not whitelisted, whitelist it with new details');
        require(_nftContract != address(0), 'Invalid contract address');
        require(_author != address(0), 'Invalid author');
        require(_authorFees + fees <= DENOMINATOR, 'Invalid author fees');
        whitelistedContracts[_nftContract].author = _author;
        whitelistedContracts[_nftContract].authorFees = _authorFees;
        emit AuthorDetailsChanged(_nftContract, _author, _authorFees, msg.sender, block.timestamp);
        return true;
    }
    
    function blacklistContract(address _nftContract) external onlyOwner() returns(bool){
        require(whitelistedContracts[_nftContract].author != address(0), 'Invalid contract');
        require(whitelistedContracts[_nftContract].isWhitelisted , 'Already blacklisted');
        whitelistedContracts[_nftContract].isWhitelisted = false;
        emit BlacklistedContract(_nftContract, msg.sender, block.timestamp);
        return true;
    }
    
    function updateFees(uint256 _newFees) external onlyOwner() returns(bool){
        require(checkFeesValid(_newFees), 'Invalid Fees');
        fees = _newFees;
        emit FeesChanged( _newFees, msg.sender, block.timestamp);
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
        require(supportedPriceTokens[_priceToken], 'Invalid price token');
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

//VIEW FUNCTIONS
    function NFTSaleDetail(address _nftContract, uint256 _nftId) external view returns(Sale memory){
        uint256 saleId = nftSaleIds[_nftContract][_nftId].currentSaleId;
        require(saleId > 0, 'This NFT is not listed');
        return sales[_nftContract][saleId];
    }

    function getFeesDetails(address _priceToken) external view returns(uint256, uint256){
        return (feesDetail.collectedPerToken[_priceToken], feesDetail.withdrawalPerToken[_priceToken]);
    }

    function getNFTContractPriceDetails(address _nftContract, address _priceToken) external view returns(uint256, uint256){
        return (whitelistedContracts[_nftContract].volumePerToken[_priceToken], whitelistedContracts[_nftContract].feesPerToken[_priceToken]);
    }
    
    function getAllSaleIds(address _nftContract, uint256 _nftId) external view returns(uint256[] memory){
        return nftSaleIds[_nftContract][_nftId].allSaleIds;
    }

    function priceTokensList() external view returns(address[] memory){
        return supportedPriceTokensInternal;
    }

    function getNFTContracts() external view returns(address[] memory){
        return whitelistedContractsInternal;
    }
    
    
//INTERNAL FUNCTIONS
    function checkFeesValid(uint256 _fees) internal view returns(bool){
        for(uint256 i = 0; i < whitelistedContractsInternal.length; i++){
            if(whitelistedContracts[whitelistedContractsInternal[i]].authorFees + _fees > DENOMINATOR){
                return false;
            }
        }
        return true;
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

    receive() payable external{}
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