// SPDX-License-Identifier: MIT

// 2021-04-10 - Release Version

pragma solidity 0.7.6;

// @openzeppelin/contracts/utils/Context.sol introduces execution context to replace msg.sender with _msgSender()
// implement admin role
import "./Ownable.sol";

// interfaces for fetching ownership of common and wrapped Cryptopunks
interface ICryptoPunks {
	function punkIndexToAddress(uint) external view returns(address);
}
interface IWrappedPunks {
	function ownerOf(uint256) external view returns (address);
}

contract StitchedPunksShop is Ownable {
    // access to existing CryptoPunks and WrappedPunks contracts
	ICryptoPunks internal CryptoPunks = ICryptoPunks(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);
	IWrappedPunks internal WrappedPunks = IWrappedPunks(0xb7F7F6C52F2e2fdb1963Eab30438024864c313F6);

    // current price for submitting an order
    uint256 public currentOrderPrice = 1 ether;

    // order details
    struct OrderDetails {
        // punk ID this order refers to:
        uint16 punkId;
        // current status of order:
        // 0 = "not created yet"
        // 10 = "order created and paid"
        // 20 = "crafting StitchedPunk"
        // 30 = "shipped"
        // 40 = "received and NFT redeemed"
        uint8 status;
        // owner who submitted the order:
        address owner;
    }

    // order status for punk ID
    uint16[] public orderedPunkIds;
    mapping(uint16 => OrderDetails) public orderStatus;

    // events
    event OrderCreated(uint16 indexed punkId, address indexed owner);
    event OrderUpdated(uint16 indexed punkId, uint8 indexed newStatus);

    function withdraw() external onlyOwner() {
        payable(owner()).transfer(address(this).balance);
    }

    function setOrderPrice(uint256 newPrice) external onlyOwner() {
        currentOrderPrice = newPrice;
    }

    // returns current owner of a given CryptoPunk (if common CryptoPunk)
    function getOwnerForCryptoPunk(uint16 punkIndex) public view returns (address) {
        return CryptoPunks.punkIndexToAddress(punkIndex);
    }

    // returns current owner of a given WrappedPunk (if wrapped CryptoPunk)
    function getOwnerForWrappedPunk(uint16 punkIndex) public view returns (address) {
        try WrappedPunks.ownerOf(punkIndex) returns (address wrappedPunkOwner) {
            return wrappedPunkOwner;
        } catch Error(string memory) {
            // catches failing revert() and require()
            // ERC721: if token does not exist, require() fails in target contract
            return address(0);
        } catch (bytes memory) {
            // low-level: catches a failing assertion, etc.
            return address(0);
        }
    }

    // checks if wallet owns a given CryptoPunk
    function isOwnerOfPunk(address wallet, uint16 punkIndex) public view returns (bool) {
        return getOwnerForCryptoPunk(punkIndex) == wallet || getOwnerForWrappedPunk(punkIndex) == wallet;
    }

    function submitOrder(uint16 punkIndex) external payable {
        // currentOrderPrice has to be paid
        require(msg.value >= currentOrderPrice, "price is too low");
        // sender has to be owner of the punk (common or wrapped)
        require(isOwnerOfPunk(_msgSender(), punkIndex), "you need to own this punk");
        // punk must not already be ordered
        require(orderStatus[punkIndex].status == 0, "punk was already ordered");

        // save order details
        orderStatus[punkIndex] = OrderDetails(punkIndex, 10, _msgSender());
        orderedPunkIds.push(punkIndex);

        emit OrderCreated(punkIndex, _msgSender());
    }

    function updateOrderStatus(uint16 punkIndex, uint8 newStatus) public onlyOwner() {
        // punk has to be ordered already
        require(orderStatus[punkIndex].status != 0, "punk was not yet ordered");

        // update order status
        orderStatus[punkIndex].status = newStatus;

        emit OrderUpdated(punkIndex, newStatus);
    }

    // StitchedPunksNFT contract address
    address public stitchedPunksNFTAddress = address(0);

    // will be called after the StitchedPunksNFT contract was deployed
    function setStitchedPunksNFTAddress(address newAddress) public onlyOwner() {
        stitchedPunksNFTAddress = newAddress;
    }

    // update order status when the NFT is redeemed/minted (must be called from the StitchedPunksNFT contract)
    function updateOrderRedeemNFT(uint16 punkIndex) external {
        require(stitchedPunksNFTAddress == _msgSender(), "caller is not the StitchedPunksNFT contract");

        // update order status: 40 = "received and NFT redeemed"
        uint8 newStatus = 40;

        // punk has to be ordered already
        require(orderStatus[punkIndex].status != 0, "punk was not yet ordered");

        // update order status
        orderStatus[punkIndex].status = newStatus;

        emit OrderUpdated(punkIndex, newStatus);
    }
}