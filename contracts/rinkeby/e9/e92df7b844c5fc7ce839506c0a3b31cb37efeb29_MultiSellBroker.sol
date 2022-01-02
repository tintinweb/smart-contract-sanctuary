/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

// librray for TokenDets
library TokenDetArrayLib {
    // Using for array of strcutres for storing mintable address and token id
    using TokenDetArrayLib for TokenDets;

    struct TokenDet {
        address NFTAddress;
        uint256 tokenID;
    }

    // custom type array TokenDets
    struct TokenDets {
        TokenDet[] array;
    }

    function addTokenDet(
        TokenDets storage self,
        TokenDet memory _tokenDet
        // address _mintableAddress,
        // uint256 _tokenID
    ) public {
        if (!self.exists(_tokenDet)) {
            self.array.push(_tokenDet);
        }
    }

    function getIndexByTokenDet(
        TokenDets storage self,
        TokenDet memory _tokenDet
    ) internal view returns (uint256, bool) {
        uint256 index;
        bool tokenExists = false;
        for (uint256 i = 0; i < self.array.length; i++) {
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

    function removeTokenDet(
        TokenDets storage self,
        TokenDet memory _tokenDet
    ) internal returns (bool) {
        (uint256 i, bool tokenExists) = self.getIndexByTokenDet(_tokenDet);
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
        for (uint256 i = 0; i < self.array.length; i++) {
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
    constructor () internal {
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



// library for erc20address array 
library ERC20Addresses {
    using ERC20Addresses for erc20Addresses;

    struct erc20Addresses {
        address[] array;
    }

    function addERC20Tokens(erc20Addresses storage self, address erc20address)
        external
    {
        self.array.push(erc20address);
    }

    function getIndexByERC20Token(
        erc20Addresses storage self,
        address _ercTokenAddress
    ) internal view returns (uint256, bool) {
        uint256 index;
        bool exists;

        for (uint256 i = 0; i < self.array.length; i++) {
            if (self.array[i] == _ercTokenAddress) {
                index = i;
                exists = true;

                break;
            }
        }
        return (index, exists);
    }

    function removeERC20Token(
        erc20Addresses storage self,
        address _ercTokenAddress
    ) internal {
       for (uint256 i = 0; i < self.array.length; i++) {
            if (
                self.array[i] == _ercTokenAddress 
            ) {
                delete self.array[i];
            }
        }
    }
    function exists(
        erc20Addresses storage self,
        address _ercTokenAddress
    ) internal view returns (bool) {
        for (uint256 i = 0; i < self.array.length; i++) {
            if (
                self.array[i] == _ercTokenAddress 
            ) {
                return true;
            }
        }
        return false;
    }
}


interface IERC20 {
    
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public returns (bytes4);
}

contract ERC721Holder is IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract IMintableToken {

    // Required methods
    function ownerOf(uint256 _tokenId) external view returns (address owner);

    function royalities(uint256 _tokenId) public view returns (uint256);

    function creators(uint256 _tokenId) public view returns (address payable);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public;

    function getApproved(uint256 tokenId)
        public
        view
        returns (address operator);

    function isApprovedForAll(address owner, address operator) public view returns (bool);

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID)
        external
        view
        returns (bool);
}

contract Storage is Ownable {
    using ERC20Addresses for ERC20Addresses.erc20Addresses;
    mapping (address=>uint) public brokerage;

    struct auction {
        uint256[] tokenIds;
        uint256[] buyPrices;
        address erc721;
        address erc20Token;
        address seller;
        bool active;
    }

    auction[] auctionList;

    uint[] public tokenOnSale;
    mapping (address=>uint[]) public tokenOnSalePerUser;

    ERC20Addresses.erc20Addresses erc20TokensArray;

    function getErc20Tokens()
        public
        view
        returns (address[] memory)
    {
        return erc20TokensArray.array;
    }

    function getUserTokensLength(address seller) public view returns (uint){
        return tokenOnSalePerUser[seller].length;
    }

    function getOnSaleLength() public view returns (uint){
        return tokenOnSale.length;
    }

    function auctions(uint index)public view returns(auction memory){
        auction memory _auction = auctionList[index];
        require(_auction.active, "MultiSellBroker: Querying non-existing auction.");
        return _auction;
    }

    function addERC20TokenPayment(address _erc20Token, uint _brokerage) public onlyOwner {
        erc20TokensArray.addERC20Tokens(_erc20Token);
        brokerage[_erc20Token] = _brokerage;
    }

    function updateBrokerage(address _erc20Token, uint _brokerage) public onlyOwner {
        brokerage[_erc20Token] = _brokerage;
    }

}

contract BrokerModifiers is Storage {
    modifier erc20Allowed(address _erc20Token) {
        if (_erc20Token != address(0)) {
            require(
                erc20TokensArray.exists(_erc20Token),
                "MultiSellBroker: ERC20 not allowed"
            );
        }
        _;
    }

    modifier tokenCreatorOnly(uint256[] memory tokenIDs, address _mintableToken) {
        IMintableToken Token = IMintableToken(_mintableToken);
        // Sender will be owner only if no have bidded on auction.
        for(uint i=0; i<tokenIDs.length; i++){
            require(
                IMintableToken(_mintableToken).ownerOf(tokenIDs[i]) == msg.sender && IMintableToken(_mintableToken).creators(tokenIDs[i]) == msg.sender,
                "MultiSellBroker: Seller must be creator."
            );
        }
        _;
    }
}


contract MultiSellBroker is ERC721Holder, BrokerModifiers {
    
    // events
    event Buy(
        address indexed collection,
        uint256[] tokenIds,
        address indexed seller,
        address indexed buyer,
        uint256[] amount,
        uint256 time,
        address ERC20Address
    );
    event OnSale(
        address indexed collection,
        uint256[] indexed tokenId,
        address indexed seller,
        uint256[] amount,
        uint256 time,
        address ERC20Address
    );
    event OffSale(
        address indexed collection,
        uint256[] indexed tokenId,
        address indexed seller,
        uint256 time,
        address ERC20Address
    );

    mapping(address => uint256) brokerageBalance;

    constructor(uint _brokerage) public {
        brokerage[address(0)] = _brokerage;
        transferOwnership(msg.sender);
    }

    function removeERC20TokenPayment(address _erc20Token)
        public
        erc20Allowed(_erc20Token)
        onlyOwner
    {
        erc20TokensArray.removeERC20Token(_erc20Token);
    }

    function buy(uint index)
        public
        payable
    {

        require(index < auctionList.length, "MultiSellBroker: Invalid Index");

        auction storage _auction = auctionList[index];
        IMintableToken Token = IMintableToken(_auction.erc721);

        require(_auction.active, "MultiSellBroker: Index doesn't exists"); 
        require(_auction.seller != msg.sender, "MultiSellBroker: Seller can't by his own NFT");

        uint totalPrice = 0;
        
        for(uint i=0; i<_auction.tokenIds.length; i++){
            totalPrice += _auction.buyPrices[i];
        }
        
        uint seller_fund = ((10000 - brokerage[_auction.erc20Token]) * totalPrice) / 10000;
        uint brokerageAmount =  totalPrice - seller_fund;

        if (_auction.erc20Token == address(0)) {
            require(msg.value >= totalPrice, "MultiSellBroker: Insufficient Payment");
            address payable seller = address(uint160(_auction.seller));
            seller.transfer(seller_fund);
        } else {
            IERC20 erc20Token = IERC20(_auction.erc20Token);
            require(
                erc20Token.allowance(msg.sender, address(this)) >=
                    totalPrice,
                "MultiSellBroker: Insufficient spent allowance "
            );
            // transfer seller_fund to creator
            erc20Token.transferFrom(msg.sender, _auction.seller, seller_fund);
            // transfer brokerage amount to broker
            erc20Token.transferFrom(msg.sender, address(this), brokerageAmount);
        }
        brokerageBalance[_auction.erc20Token] += brokerageAmount;

        // Transfer the NFTs to buyer.
        for (uint i=0; i<_auction.tokenIds.length; i++){
            Token.safeTransferFrom(address(this), msg.sender, _auction.tokenIds[i]);
        }

        // Buy event
        emit Buy(
            _auction.erc721,
            _auction.tokenIds,
            _auction.seller,
            msg.sender,
            _auction.buyPrices,
            block.timestamp,
            _auction.erc20Token
        );

        _auction.active = false;
        _removeIndexFromTokenOnSale(index);
        _removeIndexFromTokenOnSalePerUser(index, msg.sender);
    }

    function withdraw() public onlyOwner {
        msg.sender.transfer(brokerageBalance[address(0)]);
        brokerageBalance[address(0)] = 0;
    }

    function withdrawERC20(address _erc20Token) public onlyOwner {
        require(
            erc20TokensArray.exists(_erc20Token),
            "MultiSellBroker: This erc20token payment not allowed"
        );
        IERC20 erc20Token = IERC20(_erc20Token);
        erc20Token.transfer(msg.sender, brokerageBalance[_erc20Token]);
        brokerageBalance[_erc20Token] = 0;
    }

    function putOnSale(
        uint256[] memory _tokenIds,
        uint256[] memory _buyPrices,
        address _mintableToken,
        address _erc20Token
    )
        public
        erc20Allowed(_erc20Token)
        tokenCreatorOnly(_tokenIds, _mintableToken)
    {
        IMintableToken Token = IMintableToken(_mintableToken);

        require(
            Token.isApprovedForAll(msg.sender, address(this)),
            "MultiSellBroker: Broker not approved for all."
        );

        require(_tokenIds.length == _buyPrices.length, "MultiSellBroker: Tokens and Prices must be same length.");

        auction memory newAuction = auction(
            _tokenIds,
            _buyPrices,
            _mintableToken,
            _erc20Token,
            msg.sender,
            true
        );

        uint index = auctionList.push(newAuction) - 1;

        // Update the stats.
        tokenOnSalePerUser[msg.sender].push(index);
        tokenOnSale.push(index);

        // OnSale event
        emit OnSale(
            _mintableToken,
            _tokenIds,
            msg.sender,
            _buyPrices,
            block.timestamp,
            newAuction.erc20Token
        );

        for (uint i=0; i<_tokenIds.length; i++){
            Token.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
        }
    }

    function _removeIndexFromTokenOnSale(uint index) private{
        for (uint256 i = 0; i < tokenOnSale.length; i++) {
            if (
                tokenOnSale[i] == index 
            ) {
                tokenOnSale[i] = tokenOnSale[tokenOnSale.length - 1];
                tokenOnSale.pop();
            }
        }
    }

    function _removeIndexFromTokenOnSalePerUser(uint index, address seller) private{
        for (uint256 i = 0; i < tokenOnSalePerUser[seller].length; i++) {
            if (
                tokenOnSalePerUser[seller][i] == index 
            ) {
                tokenOnSalePerUser[seller][i] = tokenOnSalePerUser[seller][tokenOnSalePerUser[seller].length - 1];
                tokenOnSalePerUser[seller].pop();
            }
        }
    }

    function putSaleOff(uint index)
        public
    {

        require(index < auctionList.length, "MultiSellBroker: Invalid Index");

        auction storage _auction = auctionList[index];
        IMintableToken Token = IMintableToken(_auction.erc721);

        require(_auction.seller == msg.sender, "MultiSellBroker: Only seller executable");
        require(_auction.active, "MultiSellBroker: Index doesn't exists"); 
        

        for (uint i=0; i<_auction.tokenIds.length; i++){
            Token.safeTransferFrom(address(this), msg.sender, _auction.tokenIds[i]);
        }

        // OffSale event
        emit OffSale(
            _auction.erc721,
            _auction.tokenIds,
            msg.sender,
            block.timestamp,
            _auction.erc20Token
        );

        _auction.active = false;
        _removeIndexFromTokenOnSale(index);
        _removeIndexFromTokenOnSalePerUser(index, msg.sender);
    }

}