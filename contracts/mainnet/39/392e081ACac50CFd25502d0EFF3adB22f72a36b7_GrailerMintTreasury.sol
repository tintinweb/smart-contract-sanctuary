// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IGrailer {
    function mintPublic(uint numberOfTokens) external payable;
    function flipSaleStatus() external;
    function transferOwnership(address newOwner) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function balanceOf(address owner) external returns (uint256);
    function ownerOf(uint256 tokenId) external returns (address);
    function withdraw() external;
}

contract GrailerMintTreasury is Ownable {

    event Buy(
        address indexed owner,
        uint256 numberOfTokens,
        uint256 totalPrice,
        bool grailerOnly
    );

    IGrailer public Grailer;
    address public daoAddress;
    address public nftContract;

    bool public saleIsActive;
    bool public saleIsActiveGrailerOnly;
    uint256 public maxByMint;
    uint256 public fixedPrice;
    uint256 public trancheStart;
    uint256 public trancheEnd;
    uint256 public prevTokenId;

    constructor(address _nftContract) {
        nftContract = _nftContract;
        daoAddress = 0x63fE60e3373De8480eBe56Db5B153baB1A431E38;
        maxByMint = 10;
        fixedPrice = 1.25 ether;
        Grailer = IGrailer(nftContract);
    }

    function mintBatch(uint numberOfBatches, uint batchSize) external payable onlyOwner {
        Grailer.flipSaleStatus();
        for(uint i=1; i<=numberOfBatches; i++) {
            Grailer.mintPublic{ value: msg.value / numberOfBatches }(batchSize);
        }
        Grailer.flipSaleStatus();
    }

    function withdrawNft(uint _start, uint _end) external onlyOwner {
        for(uint i=_start; i <= _end; i++) {
            Grailer.safeTransferFrom(address(this), daoAddress, i);
        }
    }

    function transferNftOwnership(address _address) external onlyOwner {
        Grailer.transferOwnership(_address);
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0);
        _withdraw(daoAddress, balance);
    }
 
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Tx failed");
    }

    function setDaoAddress(address _daoAddress) external onlyOwner {
        daoAddress = _daoAddress;
    }

    function flipSaleStatus() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipSaleGrailerOnlyStatus() external onlyOwner {
        saleIsActiveGrailerOnly = !saleIsActiveGrailerOnly;
    }

    function setFixedPrice(uint256 _fixedPrice) external onlyOwner {
        fixedPrice = _fixedPrice;
    }

    function setMaxByMint(uint256 _maxByMint) external onlyOwner {
        maxByMint = _maxByMint;
    }

    function setTranche(uint256 _trancheStart, uint256 _trancheEnd) external onlyOwner {
        require(
            Grailer.ownerOf(_trancheStart) == address(this) 
            && Grailer.ownerOf(_trancheEnd) == address(this),
            "Not owned"
        );
        trancheStart = _trancheStart;
        trancheEnd = _trancheEnd;
        prevTokenId = _trancheStart-1;
    }

    function buyPublic(uint numberOfTokens) external payable {
        require(saleIsActive, "Sale not active");
        require(fixedPrice * numberOfTokens <= msg.value, "Eth val incorrect");
        _transfer(numberOfTokens);
        emit Buy(msg.sender, numberOfTokens, msg.value, false);
    }

    function buyGrailerOnly(uint numberOfTokens) external payable {
        require(saleIsActiveGrailerOnly, "Grailer sale not active");
        require(fixedPrice * numberOfTokens <= msg.value, "Eth val incorrect");
        require(Grailer.balanceOf(msg.sender) > 0, "Must be a Grailer");
        _transfer(numberOfTokens);
        emit Buy(msg.sender, numberOfTokens, msg.value, true);
    }

    function _transfer(uint numberOfTokens) private {
        require(numberOfTokens <= maxByMint, "Max per buy exceeded");
        require(prevTokenId + numberOfTokens <= trancheEnd, "No more available");
        for(uint i = 1; i <= numberOfTokens; i++) {
            Grailer.safeTransferFrom(address(this), msg.sender, prevTokenId + 1);
            prevTokenId = prevTokenId + 1;
        }
    }

    function withdrawFromGrailer() external onlyOwner {
        Grailer.withdraw();
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