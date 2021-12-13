/**
 *Submitted for verification at BscScan.com on 2021-12-13
*/

// File: contracts/utils/TokenDetArrayLib.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// librray for TokenDets
library TokenDetArray {
    // Using for array of strcutres for storing mintable address and token id
    using TokenDetArray for TokenDets;

    struct TokenDet {
        address NFTAddress;
        uint tokenID;
    }

    // custom type array TokenDets
    struct TokenDets {
        TokenDet[] array;
    }

    function add(
        TokenDets storage self,
        TokenDet memory _tokenDet
    ) public {
        if (!self.exists(_tokenDet)) {
            self.array.push(_tokenDet);
        }
    }

    function getIndexByTokenDet(
        TokenDets storage self,
        TokenDet memory _tokenDet
    ) internal view returns (uint, bool) {
        uint index;
        bool tokenExists = false;
        for (uint i = 0; i < self.array.length; i++) {
            if (
                self.array[i].NFTAddress == _tokenDet.NFTAddress &&
                self.array[i].tokenID == _tokenDet.tokenID 
            ) {
                index = i;
                tokenExists = true;
                break;
            }
        }
        return (index, tokenExists);
    }

    function remove(
        TokenDets storage self,
        TokenDet memory _tokenDet
    ) internal returns (bool) {
        (uint i, bool tokenExists) = self.getIndexByTokenDet(_tokenDet);
        if (tokenExists == true) {
            self.array[i] = self.array[self.array.length - 1];
            self.array.pop();
            return true;
        }
        return false;
    }

    function exists(
        TokenDets storage self,
        TokenDet memory _tokenDet
    ) internal view returns (bool) {
        for (uint i = 0; i < self.array.length; i++) {
            if (
                self.array[i].NFTAddress == _tokenDet.NFTAddress &&
                self.array[i].tokenID == _tokenDet.tokenID
            ) {
                return true;
            }
        }
        return false;
    }
}

// File: contracts/utils/Ownable.sol

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    // event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        // address msgSender = _msgSender();
        _owner = msg.sender;
        // emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        // emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

// File: contracts/utils/AddressArrayLib.sol


pragma solidity ^0.8.0;

// library for address array 
library AddressArray {
    using AddressArray for addresses;

    struct addresses {
        address[] array;
    }

    function add(addresses storage self, address _address)
        external
    {
        if(! exists(self, _address)){
            self.array.push(_address);
        }
    }

    function getIndexByAddress(
        addresses storage self,
        address _address
    ) internal view returns (uint, bool) {
        uint index;
        bool exists_;

        for (uint i = 0; i < self.array.length; i++) {
            if (self.array[i] == _address) {
                index = i;
                exists_ = true;

                break;
            }
        }
        return (index, exists_);
    }

    function remove(
        addresses storage self,
        address _address
    ) internal {
       for (uint i = 0; i < self.array.length; i++) {
            if (
                self.array[i] == _address 
            ) {
                delete self.array[i];
            }
        }
    }


    function exists(
        addresses storage self,
        address _address
    ) internal view returns (bool) {
        for (uint i = 0; i < self.array.length; i++) {
            if (
                self.array[i] == _address 
            ) {
                return true;
            }
        }
        return false;
    }
}

// File: contracts/utils/UintArrayLib.sol

pragma solidity ^0.8.0;

// library for uint array 
library UintArray {
    using UintArray for uints;

    struct uints {
        uint[] array;
    }

    function add(uints storage self, uint _uint)
        external
    {
        if(! exists(self, _uint)){
            self.array.push(_uint);
        }
    }

    function getIndexByUint(
        uints storage self,
        uint _uint
    ) internal view returns (uint, bool) {
        uint index;
        bool exists_;

        for (uint i = 0; i < self.array.length; i++) {
            if (self.array[i] == _uint) {
                index = i;
                exists_ = true;

                break;
            }
        }
        return (index, exists_);
    }

    function remove(
        uints storage self,
        uint _uint
    ) internal {
       for (uint i = 0; i < self.array.length; i++) {
            if (
                self.array[i] == _uint 
            ) {
                delete self.array[i];
            }
        }
    }


    function exists(
        uints storage self,
        uint _uint
    ) internal view returns (bool) {
        for (uint i = 0; i < self.array.length; i++) {
            if (
                self.array[i] == _uint 
            ) {
                return true;
            }
        }
        return false;
    }
}

// File: contracts/utils/Storage.sol

pragma solidity ^0.8.0;





interface IERC20 {
    
    function transfer(address recipient, uint amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint value
    );
}

interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC1155Receiver is IERC165 {

    function onERC1155Received(
        address operator,
        address from,
        uint id,
        uint value,
        bytes calldata data
    )
        external
        returns(bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint[] calldata ids,
        uint[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

interface IERC1155 is IERC165 {
   
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint id, uint value);
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint[] ids,
        uint[] values
    );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint indexed id);
    function balanceOf(address account, uint id) external view returns (uint);
    function balanceOfBatch(address[] calldata accounts, uint[] calldata ids)
        external
        view
        returns (uint[] memory
    );
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint id,
        uint amount,
        bytes calldata data
    ) external;
    function safeBatchTransferFrom(
        address from,
        address to,
        uint[] calldata ids,
        uint[] calldata amounts,
        bytes calldata data
    ) external;
    function royalities(uint _tokenId) external returns (uint);
    function creators(uint _tokenId) external returns(address payable);
}

abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint,
        uint,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint[] memory,
        uint[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

contract Storage is Ownable {
    
    // Setting up libraries 
    using TokenDetArray for TokenDetArray.TokenDets;
    using AddressArray for AddressArray.addresses;
    // using UintArray for UintArray.uints;

    AddressArray.addresses erc20TokensArray;
    // Mapping to store all the brokerage collected
    mapping (address=>uint) public brokerage;

    struct bidStruct {
        address[] bidders;
        uint[] quanties;
        uint[] bidAmounts;
    }

    struct TokenDet {
        address NFTAddress;
        uint tokenID;
    }    

    // Sale details
    struct auction {
        uint quantity;
        bidStruct bids;
        uint auctionType;
        uint startingPrice;
        uint buyPrice;
        uint startingTime;
        uint closingTime;
        address erc20Token;
    }

    // Master data strcture
    /**
     Master data structure explaination
     {
        ERC1155Address: {
            TokenID: {
                Seller: SellDetalis
            }
        }
     }
     */
    mapping(
        address => mapping(
            uint => mapping(
                address => auction
            )
        )
    ) public masterData;


    mapping(
        address => mapping(
            uint => AddressArray.addresses
        )
    ) sellerKeys;
    

    function getSellerKeys(address _erc1155, uint _tokenId) view public returns (address[] memory) {
        return sellerKeys[_erc1155][_tokenId].array;
    }

    //auction type :
    // 1 : only direct buy
    // 2 : only bid
    // 3 : both buy and bid

    mapping(address => TokenDetArray.TokenDets) tokenOnMarketplacePerUser;
    mapping(address => TokenDetArray.TokenDets) tokenOnFlatSalePerUser;
    mapping(address => TokenDetArray.TokenDets) tokenOnAuctionPerUser;
    TokenDetArray.TokenDets tokenOnMarketplace;
    TokenDetArray.TokenDets tokenOnFlatSale;
    TokenDetArray.TokenDets tokenOnAuction;

    mapping(address => uint) brokerageBalance;

    function getTokenOnMarketplacePerUser(address _seller) view public returns(TokenDetArray.TokenDet[] memory) {
        return tokenOnMarketplacePerUser[_seller].array;
    }

    function getTokenOnFlatSalePerUser(address _seller) view public returns(TokenDetArray.TokenDet[] memory) {
        return tokenOnFlatSalePerUser[_seller].array;
    }

    function getTokenOnAuctionPerUser(address _seller) view public returns(TokenDetArray.TokenDet[] memory) {
        return tokenOnAuctionPerUser[_seller].array;
    }

    function getTokenOnMarketplace() view public returns(TokenDetArray.TokenDet[] memory) {
        return tokenOnMarketplace.array;
    }

    function getTokenOnFlatSale() view public returns(TokenDetArray.TokenDet[] memory) {
        return tokenOnFlatSale.array;
    }

    function getTokenOnAuction() view public returns(TokenDetArray.TokenDet[] memory) {
        return tokenOnAuction.array;
    }


    function getErc20Tokens()
        public
        view
        returns (address[] memory)
    {
        return erc20TokensArray.array;
    }

    /**
     * Internal function update all mapping on the basis of NFT's quantity
     */
    function updateMappings(address _erc1155, uint _tokenId, address payable _seller) internal {
        TokenDetArray.TokenDet memory _tokenDet = TokenDetArray.TokenDet(_erc1155, _tokenId);
        if (masterData[_erc1155][_tokenId][_seller].quantity > 0){
            sellerKeys[_erc1155][_tokenId].add(_seller);
            tokenOnMarketplace.add(_tokenDet);
            tokenOnMarketplacePerUser[_seller].add(_tokenDet);
            if (masterData[_erc1155][_tokenId][_seller].auctionType == 1){
                tokenOnFlatSalePerUser[_seller].add(_tokenDet);
                tokenOnAuctionPerUser[_seller].remove(_tokenDet);
                tokenOnFlatSale.add(_tokenDet);
                tokenOnAuction.remove(_tokenDet);
            }else{
                tokenOnFlatSalePerUser[_seller].remove(_tokenDet);
                tokenOnAuctionPerUser[_seller].add(_tokenDet);
                tokenOnFlatSale.remove(_tokenDet);
                tokenOnAuction.add(_tokenDet);
            }
        } else {
            sellerKeys[_erc1155][_tokenId].remove(_seller);
            uint _totalOnSale = 0;
            for(uint i=0; i < sellerKeys[_erc1155][_tokenId].array.length; i++){
                _totalOnSale += masterData[_erc1155][_tokenId][_seller].quantity;
            }
            if(_totalOnSale == 0){
                tokenOnMarketplacePerUser[_seller].remove(_tokenDet);
                tokenOnFlatSalePerUser[_seller].remove(_tokenDet);
                tokenOnAuctionPerUser[_seller].remove(_tokenDet);
                tokenOnMarketplace.remove(_tokenDet);
                tokenOnFlatSale.remove(_tokenDet);
                tokenOnAuction.remove(_tokenDet);
            }
        }
    
    }

    function addERC20TokenPayment(address _erc20Token, uint _brokerage) public onlyOwner {
        erc20TokensArray.add(_erc20Token);
        brokerage[_erc20Token] = _brokerage;
    }


    function removeERC20TokenPayment(address _erc20Token)
        public
        erc20Allowed(_erc20Token)
        onlyOwner
    {
        erc20TokensArray.remove(_erc20Token);
    }



    function withdraw() public onlyOwner {
        payable(address(msg.sender)).transfer(brokerageBalance[address(0)]);
        brokerageBalance[address(0)] = 0;
    }

    
    function withdrawERC20(address _erc20) public erc20Allowed(_erc20) onlyOwner {
        IERC20 erc20Token = IERC20(_erc20);
        erc20Token.transfer(msg.sender, brokerageBalance[_erc20]);
        brokerageBalance[_erc20] = 0;
    }

    function updateBrokerage(address _erc20Token, uint _brokerage) public onlyOwner {
        brokerage[_erc20Token] = _brokerage;
    }

    modifier erc20Allowed(address _erc20Token) {
        if (_erc20Token != address(0)) {
            require(
                erc20TokensArray.exists(_erc20Token),
                "ERC20 not allowed"
            );
        }
        _;
    }
    
    // modifier haveSuffiecientBalance(address _erc1155, uint _tokenId, address payable _seller, uint _quantity) {
    //     IERC1155 Token = IERC1155(_erc1155);
    //     require(
    //         Token.balanceOf(_seller, _tokenId) >= _quantity,
    //         "Seller don't have sufficient balance"
    //     );
    //     _;
    // }

    modifier isSufficientNFTOnAuction(address _erc1155, uint _tokenId, address payable _seller, uint _quantity) {
        require(
            masterData[_erc1155][_tokenId][_seller].quantity >= _quantity &&
            masterData[_erc1155][_tokenId][_seller].auctionType == 2 &&
            masterData[_erc1155][_tokenId][_seller].closingTime > block.timestamp,
            "Not Enough NFT on auction"
        );
        _;
    }

    // modifier isSufficientNFTOnSale(address _erc1155, uint _tokenId, address payable _seller, uint _quantity) {
    //     require(
    //         masterData[_erc1155][_tokenId][_seller].quantity >= _quantity &&
    //         masterData[_erc1155][_tokenId][_seller].auctionType == 1,
    //         "Not Enough NFT on auction"
    //     );
    //     _;
    // }


}

// File: contracts/BrokerV3.sol


pragma solidity ^0.8.0;



contract BrokerV3 is ERC1155Holder, Storage {
    // events
    event Bid(
        address indexed collection,
        uint indexed tokenId,
        address indexed seller,
        address bidder,
        uint amouont,
        uint quantity,
        uint time,
        address ERC20Address
    );
    event Buy(
        address indexed collection,
        uint tokenId,
        address indexed seller,
        address indexed buyer,
        uint amount,
        uint quantity,
        uint time,
        address ERC20Address,
        uint saleType
    );
    event OnSale(
        address indexed collection,
        uint indexed tokenId,
        address indexed seller,
        uint auctionType,
        uint amount,
        uint quantity,
        uint time,
        address ERC20Address
    );
    event OffSale(
        address indexed collection,
        uint indexed tokenId,
        address indexed seller,
        uint time,
        address ERC20Address
    );


    constructor(uint _brokerage) {
        brokerage[address(0)] = _brokerage;
        transferOwnership(msg.sender);
    }

    /**
     Funtion to check if it have active auction or not

     */
    function haveActiveSell(
        address _erc1155,
        uint _tokenId,
        address _seller
    ) view public returns (bool) {
        auction memory _auction = masterData[_erc1155][_tokenId][_seller];
        if(_auction.auctionType == 1){
            return _auction.quantity > 0;
        } else {
            return _auction.quantity > 0 && _auction.closingTime > block.timestamp;
        }
    }

    function putOnSale(
        address _erc1155,
        uint _tokenId,
        uint _quantity,
        uint _startingPrice,
        uint _auctionType,
        uint _buyPrice,
        uint _duration,
        address _erc20
    )
        public
        erc20Allowed(_erc20)
    {
        IERC1155 Token = IERC1155(_erc1155);
        // Check if broker approved
        require(
            Token.isApprovedForAll(msg.sender, address(this)),
            "Broker Not approved"
        );

        // Check if seller have sufficient assets to put on sale.
        require(
            Token.balanceOf(msg.sender, _tokenId) >= _quantity,
            "Seller don't have sufficient copies to put on sale"
        );

        auction memory _auction = masterData[_erc1155][_tokenId][msg.sender];

        // Allow to put on sale to already on sale NFT \
        // only if it was on auction and have 0 bids and auction is over
        require(
            _auction.bids.bidders.length == 0,
            "This NFT have active or  unclaimed auction."
        );

        _auction.quantity = _quantity;
        _auction.auctionType = _auctionType;
        _auction.startingPrice = _startingPrice;
        _auction.buyPrice = _buyPrice;
        _auction.startingTime = block.timestamp;
        _auction.closingTime = block.timestamp + _duration;
        _auction.erc20Token = _erc20;

        masterData[_erc1155][_tokenId][msg.sender] = _auction;
        // Store/update all data to mappings 
        updateMappings(_erc1155, _tokenId, payable(address(msg.sender)));

        // OnSale event
        emit OnSale(
            _erc1155,
            _tokenId,
            msg.sender,
            _auctionType,
            _auction.auctionType == 1 ? _auction.buyPrice : _auction.startingPrice,
            _quantity,
            block.timestamp,
            _auction.erc20Token
        );
    }


    function _getObjects(address _erc1155, uint _tokenId, address payable _seller) 
        internal 
        returns (auction memory _auction, uint royalities, address payable creator) 
    {

        // Get objects
        IERC1155 Token = IERC1155(_erc1155);
        _auction = masterData[_erc1155][_tokenId][_seller];
        
        if (_auction.auctionType == 2){
            require(
                block.timestamp > _auction.closingTime,
                "Auction Not Over!"
            );
        }
        // Transfer royality if implemented in ERC1155 token
        try Token.royalities(_tokenId) returns (uint _royalities){
            royalities = _royalities;
        }
        catch{
            royalities = 0;
        }

        //Get Creator of ERC1155 Token
        try Token.creators(_tokenId) returns (address payable _creator){
            creator = _creator;
        }
        catch{
            creator = payable(address(0));
        }

    }

    function buy(address _erc1155, uint _tokenId, address payable _seller, uint _quantity)
        public
        payable
    {
       
        // Get Objects
        (
            auction memory _auction, 
            uint royalities, 
            address payable creator
        ) = _getObjects(_erc1155, _tokenId, _seller);
        IERC1155 Token = IERC1155(_erc1155);
        // Check if the requested quantity if available for sale
        require(_auction.quantity >= _quantity && _auction.auctionType == 1, "Requested quantity not available for sale");
        
        // Calculate funds to be transfered
        uint royality = ((royalities * _auction.buyPrice) / 10000) * _quantity;
        uint brokerageAmount = ((brokerage[_auction.erc20Token] * _auction.buyPrice) / 10000) * _quantity;
        uint seller_fund = (_auction.buyPrice * _quantity) - royality - brokerageAmount;


        // Transfer the funds
        if (_auction.erc20Token == address(0)) {
            require(msg.value >= _auction.buyPrice * _quantity, "Insufficient Payment");
            // Transfer the fund to creator if royality available
            if(royality > 0 && creator != payable(address(0))){
                creator.transfer(royality);
            }
            else{
                brokerageAmount+= royality;
            }
            _seller.transfer(seller_fund);
        } else {
            IERC20 erc20Token = IERC20(_auction.erc20Token);
            require(
                erc20Token.allowance(msg.sender, address(this)) >=
                    _auction.buyPrice * _quantity,
                "Insufficient spent allowance "
            );
            // transfer royalitiy to creator
            if(royality > 0 && creator != payable(address(0))){
                erc20Token.transferFrom(msg.sender, creator, royality);
            }
            else{
                brokerageAmount+= royality;
            }
            // transfer brokerage amount to broker
            erc20Token.transferFrom(msg.sender, address(this), brokerageAmount);
            // transfer remaining  amount to lastOwner
            erc20Token.transferFrom(msg.sender, _seller, seller_fund);
        }

        // Update the brokerage
        brokerageBalance[_auction.erc20Token] += brokerageAmount;

        // Update the Auction details
        masterData[_erc1155][_tokenId][_seller].quantity -= _quantity;
        updateMappings(_erc1155, _tokenId, _seller);

        Token.safeTransferFrom(
            _seller,
            msg.sender,
            _tokenId,
            _quantity,
            bytes("")
        );

        // Buy event
        emit Buy(
            _erc1155,
            _tokenId,
            _seller,
            msg.sender,
            _auction.buyPrice,
            _quantity,
            block.timestamp,
            _auction.erc20Token,
            _auction.auctionType
        );

    }

    function batchBuy(address _erc1155, uint _tokenId, address payable[] memory _sellers, uint[] memory _quantities)
        public
        payable
    {
        require(_sellers.length == _quantities.length, "Seller's list and Quantities list must be same");
        for (uint i = 0; i < _sellers.length; i++){
            buy(_erc1155, _tokenId, _sellers[i], _quantities[i]);
        }
    }

    function uintSum(uint[] memory _array) pure public returns (uint sum) {
        sum = 0;
        for(uint i=0; i<_array.length; i++){
            sum+=_array[i];
        }
    }

    function bid(address _erc1155, uint _tokenId, address payable _seller, uint _quantity, uint _amount)
        public
        payable
    {
        
        // Get objects
        IERC1155 Token = IERC1155(_erc1155);
        auction storage _auction = masterData[_erc1155][_tokenId][_seller];

        if (_auction.erc20Token == address(0)) {
            require(
                msg.value > _quantity*_amount,
                "Can't bid 0 amount"
            );
        } else {
            IERC20 erc20Token = IERC20(_auction.erc20Token);
            require(
                erc20Token.allowance(msg.sender, address(this)) >= _quantity * _amount,
                "Allowance is less than amount sent for bidding."
            );
            erc20Token.transferFrom(msg.sender, address(this), _quantity * _amount);
        }

        uint _totalBids = uintSum(_auction.bids.quanties);

        // Transfer the remaining quantity of NFT
        if (_totalBids < _auction.quantity){
            Token.safeTransferFrom(
                _seller, 
                address(this) , 
                _tokenId, 
                _totalBids + _quantity <= _auction.quantity ? _quantity : _auction.quantity - _totalBids, 
                bytes("")
            );
        }

        _auction.bids.bidders.push(msg.sender);
        _auction.bids.quanties.push(_quantity);
        _auction.bids.bidAmounts.push(_amount);

        // Bid event
        emit Bid(
            _erc1155,
            _tokenId,
            _seller,
            msg.sender,
            _amount,
            _quantity,
            block.timestamp,
            _auction.erc20Token
        );
    }

    function batchBid(address _erc1155, uint _tokenId, address payable[] memory _seller, uint[] memory _quantities, uint[] memory _amounts)
        public
    {
        require(_seller.length == _quantities.length && _seller.length == _amounts.length, "Number of seller, quantity and amount MUST be same.");
        for (uint i =0; i< _seller.length; i++){
            bid(_erc1155, _tokenId, _seller[i], _quantities[i], _amounts[i]);
        }
    }
    

    function _transferNFTs(
        auction memory _auction, 
        uint transferableQuantity,
        address _erc1155, 
        uint _tokenId, 
        address payable _seller,
        uint royalities,
        address payable creator,
        uint index
        )
        internal
    {
        
        // Transfer the funds
        if (_auction.erc20Token == address(0)) {
            if(royalities > 0 && creator != payable(address(0))){
                creator.transfer(((royalities * _auction.bids.bidAmounts[index]) / 10000) * transferableQuantity);
            }
            _seller.transfer(
                (_auction.bids.bidAmounts[index] * transferableQuantity) - 
                (((royalities * _auction.bids.bidAmounts[index]) / 10000) * transferableQuantity) - 
                (((brokerage[_auction.erc20Token] * _auction.bids.bidAmounts[index]) / 10000) * transferableQuantity)
            );
        } else {
            if(royalities > 0 && creator != payable(address(0))){
                IERC20(_auction.erc20Token).transfer(creator, ((royalities * _auction.bids.bidAmounts[index]) / 10000) * transferableQuantity);
            }
            IERC20(_auction.erc20Token).transfer(
                _seller,
                (
                    (_auction.bids.bidAmounts[index] * transferableQuantity) - 
                    (((royalities * _auction.bids.bidAmounts[index]) / 10000) * transferableQuantity) - 
                    (((brokerage[_auction.erc20Token] * _auction.bids.bidAmounts[index]) / 10000) * transferableQuantity)
                )
            );
        }

        // Update the brokerage
        if(royalities > 0 && creator != payable(address(0))){
            brokerageBalance[_auction.erc20Token] += (
                ((brokerage[_auction.erc20Token] * _auction.bids.bidAmounts[index]) / 10000) * transferableQuantity
            );
        }
        else{
            brokerageBalance[_auction.erc20Token] += (
                (((brokerage[_auction.erc20Token] + royalities) * _auction.bids.bidAmounts[index]) / 10000) * transferableQuantity
            );
        }
        {
            IERC1155 Token = IERC1155(_erc1155);
            // Transfer the token to bidder
            Token.safeTransferFrom(
                address(this),
                _auction.bids.bidders[index],
                _tokenId,
                transferableQuantity,
                bytes("")
            );
        }

        // Buy event
        emit Buy(
            _erc1155,
            _tokenId,
            _seller,
            _auction.bids.bidders[index],
            _auction.bids.bidAmounts[index],
            transferableQuantity,
            block.timestamp,
            _auction.erc20Token,
            2
        );

    }

    function _quickSortIndices(uint[] memory arr, int left, int right, uint[] memory indices) private pure {
        int i = left;
        int j = right;
        if (i == j) return;

        uint pivot = arr[uint(left + (right - left) / 2)];

        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                (indices[uint(i)], indices[uint(j)]) = (indices[uint(j)], indices[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            _quickSortIndices(arr, left, j, indices);
        if (i < right)
            _quickSortIndices(arr, i, right, indices);
    }

    function _reverseArray(uint[] memory values) private pure returns(uint[] memory){
        uint[] memory indices = new uint[](values.length);
        for (uint z = 0; z < indices.length; z++) {
            indices[z] = values[values.length - z - 1];
        }
        return indices;
    }

    function _getSortedIndices(auction memory _auction) internal pure returns(uint[] memory){

        // Get the bids and amounts in sorted order.
        uint[] memory _bidAmounts = _auction.bids.bidAmounts;
        uint[] memory indices  = new uint[](_bidAmounts.length);

        // Generate index array to get sorted index
        for(uint i=0; i < _bidAmounts.length; i++){
            indices[i] = i;
        }
        
        // Get sorted index
        _quickSortIndices(_bidAmounts, 0, (int(_bidAmounts.length - 1)), indices);
        
        return _reverseArray(indices);
    }

    // Collect Function are use to collect funds and NFT from Broker
    function collect(address _erc1155, uint _tokenId, address payable _seller)
        public
    {
       // Get Objects
         (
            auction memory _auction, 
            uint royalities, 
            address payable creator
        ) = _getObjects(_erc1155, _tokenId, _seller);

        uint[] memory indices = _getSortedIndices(_auction);

        // Loop through the sorted indices[i] and transfer the NFTs
        for (uint i=0; i<indices.length; i++){
            uint transferableQuantity;
            uint refundableQuantity;
            
            // Calculate the amount can be transfered or need to be refunded.
            if(_auction.quantity > _auction.bids.quanties[indices[i]]){
                transferableQuantity = _auction.bids.quanties[indices[i]];
                refundableQuantity = 0;
            } 
            else{
                transferableQuantity = _auction.quantity;
                refundableQuantity = _auction.bids.quanties[indices[i]] - _auction.quantity;
            }

            // Transfer if there is any NFT transferable 
            if(transferableQuantity > 0){
                _transferNFTs(
                    _auction, transferableQuantity, 
                    _erc1155, _tokenId, _seller, 
                    royalities, creator, indices[i]
                );

            }

            // Refund the bidders if they don't won auction for requested quantity
            if(refundableQuantity > 0){
                // refund everyone for the anount they had bidded.
                if (_auction.erc20Token == address(0)) {
                    payable(address(_auction.bids.bidders[indices[i]])).transfer(_auction.bids.bidAmounts[indices[i]] * refundableQuantity);
                } else {
                    IERC20 erc20Token = IERC20(_auction.erc20Token);
                    erc20Token.transfer(_auction.bids.bidders[indices[i]], _auction.bids.bidAmounts[indices[i]] * refundableQuantity);
                }
            }

            // Update the remaining quantity
            if (_auction.quantity > _auction.bids.quanties[indices[i]]){
                _auction.quantity -= _auction.bids.quanties[indices[i]];
            }
            else{
                _auction.quantity = 0;
            }

        }

        // Transfer the Reaminng NFT(Not won by any bidder to owner)
        // if (_auction.quantity > 0){
        //     IERC1155 Token = IERC1155(_erc1155);
        //     Token.safeTransferFrom(
        //         address(this),
        //         _seller,
        //         _tokenId,
        //         _auction.quantity,
        //         bytes("")
        //     );
        // }

        // Reset the auction
        delete masterData[_erc1155][_tokenId][_seller];

        // udpate the mappings
        updateMappings(_erc1155, _tokenId, _seller);

    }


    function putOffSale(
        address _erc1155,
        uint _tokenId
    ) public
    {

        auction memory _auction = masterData[_erc1155][_tokenId][msg.sender];

        // Allow to put on sale to already on sale NFT \
        // only if it was on auction and have 0 bids and auction is over
        require(
            _auction.bids.bidders.length == 0,
            "This NFT have active or  unclaimed auction."
        );


        // Reset the auction
        delete masterData[_erc1155][_tokenId][msg.sender];

        // udpate the mappings
        updateMappings(_erc1155, _tokenId, payable(msg.sender));

    }



}