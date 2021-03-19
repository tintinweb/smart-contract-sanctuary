/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

pragma solidity ^0.5.0;

library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}


contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () public {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}


contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () public {
        _paused = false;
    }

    /**
     * @return true if the contract is paused, false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   *  as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    assembly { size := extcodesize(addr) }  // solium-disable-line security/no-inline-assembly
    return size > 0;
  }

}

// File: contracts/marketplace/MarketplaceStorage.sol

/**
 * @title Interface for contracts conforming to ERC-20
 */
contract ERC20Interface {
  function transferFrom(address from, address to, uint tokens) public returns (bool success);
  function balanceOf(address _owner) public view returns (uint256 balance);
  function transfer(address to, uint256 value) public returns (bool);
}


/**
 * @title Interface for contracts conforming to ERC-721
 */
contract ERC721Interface {
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId) public view returns (address);
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
  function supportsInterface(bytes4) public view returns (bool);
}


contract ERC721Verifiable is ERC721Interface {
  function verifyFingerprint(uint256, bytes memory) public view returns (bool);
}


contract MarketplaceStorage {
    // ERC20Interface public acceptedToken;
    struct Order {
        // Order ID
        uint256 id;
        // Owner of the NFT
        address seller;
        // NFT registry address
        uint256 nftId;
        // NFT ids
        uint256[] assetIds;
        // whitelisted erc-20 token id
        uint256 tokenId;
        // Price (in wei) for the published item
        uint256 price;
        // Time when this sale ends
        uint256 expiresAt;
    }

    // From ERC721 registry assetId to Order (to avoid asset collision)
    // erc721 addr to nftid to order
    mapping (uint256 => Order) public orderById;

    mapping (uint256 => address) public acceptedErc20TokenById;
    mapping (uint256 => address) public nftAddressById;
    ERC20Interface public miningToken;

    mapping (uint256 => uint256[]) public ordersByNftId;
    mapping (address => uint256[]) public ordersByUser;
  
  

    uint256 tokenNum = 0;
    uint256 nftNum = 0;
    uint256 orderNum = 1000;
  
    uint256 public ownerCutPerMillion;
    uint256 public publicationFeeInWei;
    uint256 public miningFeeInWei;

    // address public legacyNFTAddress; //default nft
  

    bytes4 public constant ERC721_Interface = bytes4(0x80ac58cd);

    // EVENTS
    event OrderCreated(
        uint256 id,
        address indexed seller,
        uint256 nftId,
        uint256 tokenId,
        uint256 priceInWei,
        uint256 expiresAt
    );
    event OrderSuccessful(
        uint256 id,
        address indexed seller,
        uint256 nftId,
        uint256 tokenId,
        uint256 totalPrice,
        address indexed buyer
    );
    event OrderCancelled(
        uint256 id,
        address indexed seller,
        uint256 nftId
    );

    event ChangedPublicationFee(uint256 publicationFee);
    event ChangedOwnerCutPerMillion(uint256 ownerCutPerMillion);
    event ChangedMiningFee(uint256 miningFeeInWei);
    event ChangedMiningAddress(address miningToken);
    event AddNFTAddress(address indexed nftAddress);
    event AddTokenAddress(address indexed tokenAddress);
    event RemoveToken(uint256 indexed tokenId);
    event RemoveNFT(uint256 indexed nftId);

}

contract Marketplace is Ownable, Pausable, MarketplaceStorage {
    using SafeMath for uint256;
    using AddressUtils for address;


    constructor (address _nftAddress, address _tokenAddress) public {
        // ropsten
        // addNFTAddress(0x6eB7Fd29Ef257D110E02C14B9bFaDd7b9aD8B229);
        // addTokenAddress(0xC2D8096Fde9954984d9C45707a1dff3c646Ff6cD);
        // mainnet
        addNFTAddress(_nftAddress);//estate//0x959e104E1a4dB6317fA58F8295F586e1A978c297//0xF87E31492Faf9A91B02Ee0dEAAd50d51d56D5d4d
        addTokenAddress(_tokenAddress);//mana//0x0F5D2fB29fb7d3CFeE444a200298f468908cC942//
    }


    function setPublicationFee(uint256 _publicationFee) external onlyOwner {
        publicationFeeInWei = _publicationFee;
        emit ChangedPublicationFee(publicationFeeInWei);
    }

    function setMiningFee(uint256 _miningFeeInWei) external onlyOwner {
        miningFeeInWei = _miningFeeInWei;
        emit ChangedMiningFee(miningFeeInWei);
    }


    function setOwnerCutPerMillion(uint256 _ownerCutPerMillion) external onlyOwner {
        require(_ownerCutPerMillion < 1000000, "The owner cut should be between 0 and 999,999");

        ownerCutPerMillion = _ownerCutPerMillion;
        emit ChangedOwnerCutPerMillion(ownerCutPerMillion);
    }

    function setMiningAddress(address miningTokenAddress) public onlyOwner {
        require(miningTokenAddress.isContract(), "The mining token address must be a deployed contract");

        miningToken = ERC20Interface(miningTokenAddress);
        emit ChangedMiningAddress(miningTokenAddress);
    }


    function addNFTAddress(address nftAddress) public onlyOwner {
        _requireERC721(nftAddress);

        nftAddressById[nftNum] = nftAddress;
        nftNum += 1;
        emit AddNFTAddress(nftAddress);
    }

    function removeNFT(uint256 nftId) public onlyOwner {
        require (nftId<nftNum);

        delete nftAddressById[nftId];
        emit RemoveNFT(nftId);
    }

    function addTokenAddress(address tokenAddress) public onlyOwner {
        require(tokenAddress.isContract(), "The accepted token address must be a deployed contract");

        acceptedErc20TokenById[tokenNum] = tokenAddress;
        tokenNum += 1;
        emit AddTokenAddress(tokenAddress);
    }

    function removeToken(uint256 tokenId) public onlyOwner {
        require (tokenId<tokenNum);

        delete acceptedErc20TokenById[tokenId];
        emit RemoveToken(tokenId);
    }


    function createOrder(
        uint256 nftId,
        uint256[] memory assetIds,
        uint256 tokenId,
        uint256 priceInWei,
        uint256 expiresAt
    )
    public
    whenNotPaused
    {
        _createOrder(
          nftId,
          assetIds,
          tokenId,
          priceInWei,
          expiresAt
        );

        // mining
        if (miningFeeInWei > 0) {
            uint256 thisBalance = miningToken.balanceOf(address(this));
            if(thisBalance >= miningFeeInWei.mul(2)){
                require(
                    miningToken.transfer(msg.sender, miningFeeInWei),
                    "Transfering the mining fee to the buyer failed"
                );
                require(
                    miningToken.transfer(owner(), miningFeeInWei),
                    "Transfering the mining fee to the owner failed"
                );
            }
        }
    }

    function createManyOrders(
        uint256 nftId,
        uint256[] memory assetIds,
        uint256 tokenId,
        uint256 priceInWei,
        uint256 expiresAt
    )
    public
    whenNotPaused
    {
        require (assetIds.length>1 && assetIds.length<=100, 'support order number: 2-100');
        uint256[] memory assetId_ = new uint256[](1);
        for(uint256 idx=0; idx<assetIds.length; idx++){
            assetId_[0] = assetIds[idx];
            _createOrder(
              nftId,
              assetId_,
              tokenId,
              priceInWei,
              expiresAt
            );
        }

        // mining
        if (miningFeeInWei > 0) {
            if(miningToken.balanceOf(address(this)) >= miningFeeInWei.mul(2)){
                require(
                    miningToken.transfer(msg.sender, miningFeeInWei),
                    "Transfering the mining fee to the buyer failed"
                );
                require(
                    miningToken.transfer(owner(), miningFeeInWei),
                    "Transfering the mining fee to the owner failed"
                );
            }
        }
    }


    function cancelOrder(uint256 orderId) public whenNotPaused {
        _cancelOrder(orderId);
    }


    function executeOrder(
        uint256 nftId,
        uint256 tokenId,
        uint256 orderId,
        uint256 price
    )
    public
    whenNotPaused
    {
        _executeOrder(
          nftId,
          tokenId,
          orderId,
          price
        );
        
        // mining
        if (miningFeeInWei > 0) {
            if(miningToken.balanceOf(address(this)) >= miningFeeInWei){
                require(
                    miningToken.transfer(msg.sender, miningFeeInWei),
                    "Transfering the mining fee to the buyer failed"
                );
            }
        }
    }



    function _createOrder(
        uint256 _nftId,
        uint256[] memory _assetIds,
        uint256 _tokenId,
        uint256 priceInWei,
        uint256 expiresAt
    )
    internal
    {
        address nftAddress = nftAddressById[_nftId];
        address tokenAddress = acceptedErc20TokenById[_tokenId];
        // require(nftAddress!=address(0),'only support whitelisted nfts');
        _requireERC721(nftAddress);
        require (tokenAddress!=address(0),'only support whitelisted tokens');

        ERC721Interface nftRegistry = ERC721Interface(nftAddress);
        ERC20Interface acceptedToken = ERC20Interface(tokenAddress);

        uint256 assetId;
        address assetOwner;
        // check number of nfts
        require(_assetIds.length <= 100 && _assetIds.length > 0,"Max 100 nfts supported now");
        // check permissions
        for(uint256 idx=0; idx<_assetIds.length; idx++){
            assetId = _assetIds[idx];
            assetOwner = nftRegistry.ownerOf(assetId);
            require(msg.sender == assetOwner, "Only the owner can create orders");
            require(
                nftRegistry.getApproved(assetId) == address(this) || nftRegistry.isApprovedForAll(assetOwner, address(this)),
                "The contract is not authorized to manage the asset"
            );
            // check for duplicate
            // for(uint256 ckIdx=0; ckIdx<idx; ckIdx++){    
            //     require (_assetIds[ckIdx] != assetId, "Duplicate Assets");
            // }
        }
        require(priceInWei > 0, "Price should be bigger than 0");
        require(expiresAt > block.timestamp.add(5 minutes), "Publication should be more than 5 minute in the future");


        uint256 orderId = orderNum;

        // create order
        orderById[orderId] = Order({
            id: orderId,
            seller: assetOwner,
            nftId: _nftId,
            assetIds: _assetIds,
            tokenId:_tokenId,
            price: priceInWei,
            expiresAt: expiresAt
        });
        // add to dataset
        ordersByNftId[_nftId].push(orderId);
        ordersByUser[assetOwner].push(orderId);

        // Check if there's a publication fee and
        // transfer the amount to marketplace owner
        if (publicationFeeInWei > 0) {
            require(
                acceptedToken.transferFrom(msg.sender, owner(), publicationFeeInWei),
                "Transfering the publication fee to the Marketplace owner failed"
            );
        }

        emit OrderCreated(
            orderId,
            assetOwner,
            _nftId,
            _tokenId,
            priceInWei,
            expiresAt
        );
        // global order id
        orderNum +=1;
    }


    function _cancelOrder(uint256 _orderId) internal{
        Order memory order = orderById[_orderId];

        require(order.id == _orderId && order.id >= 1000 && order.id < orderNum, "Asset not published");
        require(order.seller == msg.sender || msg.sender == owner(), "Unauthorized user");

        address orderSeller = order.seller;
        uint256 nftId = order.nftId;

        // delete from dataset
        for(uint256 idx=0; idx<ordersByNftId[nftId].length; idx++){
            if(ordersByNftId[nftId][idx]==order.id){
                delete ordersByNftId[nftId][idx];
            }
        }
        for(uint256 idx=0; idx<ordersByUser[orderSeller].length; idx++){
            if(ordersByUser[orderSeller][idx]==order.id){
                delete ordersByUser[orderSeller][idx];
            }
        }
        // delete order
        delete orderById[_orderId];

        emit OrderCancelled(
            _orderId,
            orderSeller,
            nftId
        );
    }


    function _executeOrder(
        uint256 _nftId,
        uint256 _tokenId,
        uint256 _orderId,
        uint256 price
    )
    internal
    {
        address nftAddress = nftAddressById[_nftId];
        address tokenAddress = acceptedErc20TokenById[_tokenId];
        _requireERC721(nftAddress);
        require (tokenAddress!=address(0));

        ERC721Interface nftRegistry = ERC721Interface(nftAddress);
        ERC20Interface acceptedToken = ERC20Interface(tokenAddress);

        Order memory order = orderById[_orderId];

        require(order.id == _orderId && order.id >= 1000 && order.id< orderNum, "Asset not published");

        address seller = order.seller;

        require(seller != address(0), "Invalid address");
        require(seller != msg.sender, "Unauthorized user");
        require(order.price == price, "The price is not correct");
        require(block.timestamp < order.expiresAt, "The order expired");

        uint256 assetId;
        for(uint256 idx=0; idx<order.assetIds.length; idx++){
          assetId = order.assetIds[idx];
          require(seller == nftRegistry.ownerOf(assetId), "The seller is no longer the owner");
        }

        uint saleShareAmount = 0;

        // delete from dataset
        for(uint256 idx=0; idx<ordersByNftId[_nftId].length; idx++){
          if(ordersByNftId[_nftId][idx]==_orderId){
            delete ordersByNftId[_nftId][idx];
          }
        }
        for(uint256 idx=0; idx<ordersByUser[seller].length; idx++){
          if(ordersByUser[seller][idx]==_orderId){
            delete ordersByUser[seller][idx];
          }
        }
        // delete order
        delete orderById[_orderId];


        if (ownerCutPerMillion > 0) {
            // Calculate sale share
            saleShareAmount = price.mul(ownerCutPerMillion).div(1000000);

            // Transfer share amount for marketplace Owner
            require(
                acceptedToken.transferFrom(msg.sender, owner(), saleShareAmount),
                "Transfering the cut to the Marketplace owner failed"
            );
        }

        // Transfer sale amount to seller
        require(
            acceptedToken.transferFrom(msg.sender, seller, price.sub(saleShareAmount)),
            "Transfering the sale amount to the seller failed"
        );

        for(uint256 idx=0; idx<order.assetIds.length; idx++){
            assetId = order.assetIds[idx];
            nftRegistry.safeTransferFrom(
                seller,
                msg.sender,
                assetId
            );
        }
        // Transfer all assets owner

        emit OrderSuccessful(
            _orderId,
            seller,
            _nftId,
            _tokenId,
            price,
            msg.sender
        );
    }

    function _requireERC721(address nftAddress) internal view {
        require(nftAddress.isContract(), "The NFT Address should be a contract");

        ERC721Interface nftRegistry = ERC721Interface(nftAddress);
        require(
            nftRegistry.supportsInterface(ERC721_Interface),
            "The NFT contract has an invalid ERC721 implementation"
        );
    }


    function getAllOrders() public view returns(uint256[] memory) {
        // uint256[] result;
        uint256[] memory x;
        if(orderNum==1000){
            return(x);
        }
        // 
        uint256 zeroLen;
        uint256 orderId_;
        for(uint256 idx=1000;idx<orderNum;idx++){
            orderId_ = orderById[idx].id;
            if(orderId_==0){
                zeroLen++;
            }
        }
        // if all not vaild
        uint256 leftNum_ = orderNum-zeroLen-1000;
        if(leftNum_==0){
            return(x);
        }
        // if vaild orders found
        uint256[] memory result = new uint256[](leftNum_);
        uint256 count;
        for(uint256 idx=1000;idx<orderNum;idx++){
            orderId_ = orderById[idx].id;
            if(orderId_!=0){
                result[count] = orderId_;
                count++;
            }
        }
        return(result);
    }

    function getUserOrders(address userAddr) public view returns(uint256[] memory) {
        uint256[] memory x;
        uint256 userOrderNum = ordersByUser[userAddr].length;
        if(userOrderNum==0){
            return(x);
        }
        //
        uint256 zeroLen;
        uint256 orderId_;
        for(uint256 idx=0;idx<userOrderNum;idx++){
            orderId_ = ordersByUser[userAddr][idx];
            if(orderId_==0){
                zeroLen++;
            }
        }
        // if all not vaild
        uint256 leftNum_ = userOrderNum-zeroLen;
        if(leftNum_==0){
            return(x);
        }
        // if vaild orders found
        uint256[] memory result = new uint256[](leftNum_);
        uint256 count;
        for(uint256 idx=0;idx<userOrderNum;idx++){
            orderId_ = ordersByUser[userAddr][idx];
            if(orderId_!=0){
                result[count] = orderId_;
                count++;
            }
        }
        return(result);

    }

    function getNftOrders(uint256 nftId) public view returns(uint256[] memory) {
        uint256[] memory x;
        uint256 nftOrderNum = ordersByNftId[nftId].length;
        if(nftOrderNum==0){
            return(x);
        }
        //
        uint256 zeroLen;
        uint256 orderId_;
        for(uint256 idx=0;idx<nftOrderNum;idx++){
            orderId_ = ordersByNftId[nftId][idx];
            if(orderId_==0){
                zeroLen++;
            }
        }
        // if all not vaild
        uint256 leftNum_ = nftOrderNum-zeroLen;
        if(leftNum_==0){
            return(x);
        }
        // if vaild orders found
        uint256[] memory result = new uint256[](leftNum_);
        uint256 count;
        for(uint256 idx=0;idx<nftOrderNum;idx++){
            orderId_ = ordersByNftId[nftId][idx];
            if(orderId_!=0){
                result[count] = orderId_;
                count++;
            }
        }
        return(result);
    }

    function getOrderAssets(uint256 orderId_) public view returns(uint256[] memory) {
        Order memory order = orderById[orderId_];
        return(order.assetIds);
    }

    function getOrderInfo(uint256 orderId_) public view returns
        (uint256, address, uint256, uint256, uint256, uint256, uint256[] memory) {
        Order memory order = orderById[orderId_];
        return(order.id, order.seller, order.nftId, order.tokenId, order.price, order.expiresAt, order.assetIds);
    }
    
}