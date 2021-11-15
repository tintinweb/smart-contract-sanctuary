// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICakeNFTStore.sol";
import "./interfaces/ICakeOwnerVault.sol";
import "./interfaces/ICakeVault.sol";
import "./CakeDividend.sol";

contract CakeNFTStore is Ownable, ICakeNFTStore, CakeDividend {

    ICakeOwnerVault immutable public ownerVault;
    ICakeVault immutable public vault;

    address public oracle;

    function setOracle(address _oracle) onlyOwner external {
        oracle = _oracle;
    }

    constructor(
        IERC20 _cake, ICakeStaker _cakeStaker,
        ICakeOwnerVault _ownerVault, ICakeVault _vault,
        address _oracle
    ) CakeDividend(_cake, _cakeStaker) {
        ownerVault = _ownerVault;
        vault = _vault;
        oracle = _oracle;
    }

    uint256 public ownerFee = 25 * 1e4 / 1000;

    function setOwnerFee(uint256 fee) onlyOwner external {
        ownerFee = fee;
    }
    
    struct NFTDeployer {
        address deployer;
        uint256 staking; // 1e4
        uint256 fee; // 1e4
    }
    mapping(IERC721 => NFTDeployer) public nftDeployers;
    mapping(IERC721 => bool) public initSolds;

    address[] override public nfts;
    function nftCount() override view external returns (uint256) {
        return nfts.length;
    }
    
    mapping(IERC721 => uint256) override public totalTradingVolumes;

    function set(ICakeNFT nft, uint256 staking, uint256 fee) override external {
        require(nft.deployer() == msg.sender && staking >= 1e3 && staking <= 1e4 && fee <= 1e3);

        if (nftDeployers[nft].deployer != address(0)) {
            nfts.push(address(nft));
        }

        nftDeployers[nft] = NFTDeployer({
            deployer: msg.sender,
            staking: staking,
            fee: fee
        });
    }

    function setNFTDeployer(IERC721 nft, address deployer, uint256 staking, uint256 fee, bytes memory signature) external {
        require(signature.length == 65, "invalid signature length");

        bytes32 hash = keccak256(abi.encodePacked(msg.sender, address(nft), deployer, staking, fee));
        hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28, "invalid signature version");

        require(ecrecover(hash, v, r, s) == oracle);
        
        require(staking >= 1e3 && staking <= 1e4 && fee <= 1e3);
        
        if (nftDeployers[nft].deployer != address(0)) {
            nfts.push(address(nft));
        }

        nftDeployers[nft] = NFTDeployer({
            deployer: deployer,
            staking: staking,
            fee: fee
        });
    }

    struct Sale {
        address seller;
        uint256 price;
    }
    mapping(IERC721 => mapping(uint256 => Sale)) override public sales;

    struct OfferInfo {
        address offeror;
        uint256 price;
    }
    mapping(IERC721 => mapping(uint256 => OfferInfo[])) override public offers;
    function offerCount(IERC721 nft, uint256 nftId) override view external returns (uint256) {
        return offers[nft][nftId].length;
    }
    
    struct AuctionInfo {
        address seller;
        uint256 startPrice;
        uint256 endBlock;
    }
    mapping(IERC721 => mapping(uint256 => AuctionInfo)) override public auctions;
    
    struct Bidding {
        address bidder;
        uint256 price;
    }
    mapping(IERC721 => mapping(uint256 => Bidding[])) override public biddings;
    function biddingCount(IERC721 nft, uint256 nftId) override view external returns (uint256) {
        return biddings[nft][nftId].length;
    }

    modifier whitelist(IERC721 nft) {
        require(nftDeployers[nft].deployer != address(0));
        _;
    }

    function sell(IERC721 nft, uint256 nftId, uint256 price) whitelist(nft) override public {
        require(nft.ownerOf(nftId) == msg.sender && checkAuction(nft, nftId) != true);
        nft.transferFrom(msg.sender, address(this), nftId);
        sales[nft][nftId] = Sale({
            seller: msg.sender,
            price: price
        });
        emit Sell(nft, nftId, msg.sender, price);
    }

    function sellWithPermit(ICakeNFT nft, uint256 nftId, uint256 price,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) override external {
        nft.permit(address(this), nftId, deadline, v, r, s);
        sell(nft, nftId, price);
    }

    function checkSelling(IERC721 nft, uint256 nftId) override view public returns (bool) {
        return sales[nft][nftId].seller != address(0);
    }

    function distributeReward(IERC721 nft, uint256 nftId, address to, uint256 price) internal {
        uint256 _ownerFee = price * ownerFee / 1e4;

        cake.approve(address(ownerVault), _ownerFee);
        ownerVault.deposit(_ownerFee);
        
        NFTDeployer memory deployer = nftDeployers[nft];
        uint256 deployerFee = price * deployer.fee / 1e4;
        cake.transfer(deployer.deployer, deployerFee);
        
        uint256 staking = 0;
        if (initSolds[nft] != true) {
            staking = price * deployer.staking / 1e4;
            _stakeCake(nft, nftId, staking);
            initSolds[nft] = true;
        }

        cake.transfer(to, price - _ownerFee - deployerFee - staking);

        totalTradingVolumes[nft] += price;
    }

    function buy(IERC721 nft, uint256 nftId) override external {
        Sale memory sale = sales[nft][nftId];
        require(sale.seller != address(0));
        delete sales[nft][nftId];
        nft.transferFrom(address(this), msg.sender, nftId);
        cake.transferFrom(msg.sender, address(this), sale.price);
        distributeReward(nft, nftId, sale.seller, sale.price);
        emit Buy(nft, nftId, msg.sender, sale.price);
    }

    function cancelSale(IERC721 nft, uint256 nftId) override external {
        address seller = sales[nft][nftId].seller;
        require(seller == msg.sender);
        nft.transferFrom(address(this), seller, nftId);
        delete sales[nft][nftId];
        emit CancelSale(nft, nftId, msg.sender);
    }

    function userMint(IUserMintNFT nft) override external returns (uint256 id) {
        uint256 mintPrice = nft.mintPrice();
        id = nft.mint(msg.sender);
        cake.transferFrom(msg.sender, address(this), mintPrice);
        distributeReward(nft, id, nft.deployer(), mintPrice);
        emit UserMint(nft, id, msg.sender, mintPrice);
    }

    function offer(IERC721 nft, uint256 nftId, uint256 price) whitelist(nft) override public returns (uint256 offerId) {
        require(price > 0);
        OfferInfo[] storage os = offers[nft][nftId];
        offerId = os.length;
        os.push(OfferInfo({
            offeror: msg.sender,
            price: price
        }));

        cake.transferFrom(msg.sender, address(this), price);
        cake.approve(address(vault), price);
        vault.deposit(price);

        emit Offer(nft, nftId, offerId, msg.sender, price);
    }

    function cancelOffer(IERC721 nft, uint256 nftId, uint256 offerId) override external {
        OfferInfo[] storage os = offers[nft][nftId];
        OfferInfo memory _offer = os[offerId];
        require(_offer.offeror == msg.sender);
        uint256 price = _offer.price;
        delete os[offerId];

        vault.withdraw(price);
        cake.transfer(msg.sender, price);

        emit CancelOffer(nft, nftId, offerId, _offer.offeror);
    }

    function acceptOffer(IERC721 nft, uint256 nftId, uint256 offerId) override external {
        OfferInfo[] storage os = offers[nft][nftId];
        OfferInfo memory _offer = os[offerId];
        nft.transferFrom(msg.sender, _offer.offeror, nftId);
        uint256 price = _offer.price;
        delete os[offerId];
        
        vault.withdraw(price);
        distributeReward(nft, nftId, msg.sender, price);

        emit AcceptOffer(nft, nftId, offerId, msg.sender);
    }

    function auction(IERC721 nft, uint256 nftId, uint256 startPrice, uint256 endBlock) whitelist(nft) override public {
        require(nft.ownerOf(nftId) == msg.sender && checkSelling(nft, nftId) != true);
        nft.transferFrom(msg.sender, address(this), nftId);
        auctions[nft][nftId] = AuctionInfo({
            seller: msg.sender,
            startPrice: startPrice,
            endBlock: endBlock
        });
        emit Auction(nft, nftId, msg.sender, startPrice, endBlock);
    }

    function auctionWithPermit(ICakeNFT nft, uint256 nftId, uint256 startPrice, uint256 endBlock,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) override external {
        nft.permit(address(this), nftId, deadline, v, r, s);
        auction(nft, nftId, startPrice, endBlock);
    }

    function cancelAuction(IERC721 nft, uint256 nftId) override external {
        require(biddings[nft][nftId].length == 0);
        address seller = auctions[nft][nftId].seller;
        require(seller == msg.sender);
        nft.transferFrom(address(this), seller, nftId);
        delete auctions[nft][nftId];
        emit CancelAuction(nft, nftId, msg.sender);
    }

    function checkAuction(IERC721 nft, uint256 nftId) override view public returns (bool) {
        return auctions[nft][nftId].seller != address(0);
    }

    function bid(IERC721 nft, uint256 nftId, uint256 price) override public returns (uint256 biddingId) {
        AuctionInfo memory _auction = auctions[nft][nftId];
        require(_auction.seller != address(0) && block.number < _auction.endBlock);
        Bidding[] storage bs = biddings[nft][nftId];
        biddingId = bs.length;
        if (biddingId == 0) {
            require(_auction.startPrice <= price);
        } else {
            Bidding memory bestBidding = bs[biddingId - 1];
            require(bestBidding.price < price);
            vault.withdraw(bestBidding.price);
            cake.transfer(bestBidding.bidder, bestBidding.price);
        }
        bs.push(Bidding({
            bidder: msg.sender,
            price: price
        }));

        cake.transferFrom(msg.sender, address(this), price);
        cake.approve(address(vault), price);
        vault.deposit(price);

        emit Bid(nft, nftId, msg.sender, price);
    }

    function claim(IERC721 nft, uint256 nftId) override external {
        AuctionInfo memory _auction = auctions[nft][nftId];
        Bidding[] memory bs = biddings[nft][nftId];
        Bidding memory bidding = bs[bs.length - 1];
        require(bidding.bidder == msg.sender && block.number >= _auction.endBlock);
        delete auctions[nft][nftId];
        delete biddings[nft][nftId];
        nft.transferFrom(address(this), msg.sender, nftId);
        
        vault.withdraw(bidding.price);
        distributeReward(nft, nftId, _auction.seller, bidding.price);

        emit Claim(nft, nftId, msg.sender, bidding.price);
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
pragma solidity ^0.8.5;

import "./ICakeDividend.sol";
import "./ICakeNFT.sol";
import "./ICakeStaker.sol";
import "./IUserMintNFT.sol";

interface ICakeNFTStore is ICakeDividend {
    
    event Sell(IERC721 indexed nft, uint256 indexed nftId, address indexed owner, uint256 price);
    event Buy(IERC721 indexed nft, uint256 indexed nftId, address indexed buyer, uint256 price);
    event CancelSale(IERC721 indexed nft, uint256 indexed nftId, address indexed owner);
    event UserMint(IERC721 indexed nft, uint256 indexed nftId, address indexed minter, uint256 mintPrice);
    
    event Offer(IERC721 indexed nft, uint256 indexed nftId, uint256 indexed offerId, address offeror, uint256 price);
    event CancelOffer(IERC721 indexed nft, uint256 indexed nftId, uint256 indexed offerId, address offeror);
    event AcceptOffer(IERC721 indexed nft, uint256 indexed nftId, uint256 indexed offerId, address acceptor);

    event Auction(IERC721 indexed nft, uint256 indexed nftId, address indexed owner, uint256 startPrice, uint256 endBlock);
    event CancelAuction(IERC721 indexed nft, uint256 indexed nftId, address indexed owner);
    event Bid(IERC721 indexed nft, uint256 indexed nftId, address indexed bidder, uint256 price);
    event Claim(IERC721 indexed nft, uint256 indexed nftId, address indexed bidder, uint256 price);
    
    function nfts(uint256 index) external returns (address);
    function nftCount() view external returns (uint256);
    function totalTradingVolumes(IERC721 nft) view external returns (uint256);

    function set(ICakeNFT nft, uint256 staking, uint256 fee) external;

    function sales(IERC721 nft, uint256 nftId) external returns (
        address seller,
        uint256 price
    );

    function offers(IERC721 nft, uint256 nftId, uint256 index) external returns (
        address offeror,
        uint256 price
    );
    function offerCount(IERC721 nft, uint256 nftId) view external returns (uint256);

    function auctions(IERC721 nft, uint256 nftId) external returns (
        address seller,
        uint256 startPrice,
        uint256 endBlock
    );

    function biddings(IERC721 nft, uint256 nftId, uint256 index) external returns (
        address bidder,
        uint256 price
    );
    function biddingCount(IERC721 nft, uint256 nftId) view external returns (uint256);

    function sell(IERC721 nft, uint256 nftId, uint256 price) external;
    function sellWithPermit(ICakeNFT nft, uint256 nftId, uint256 price,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function checkSelling(IERC721 nft, uint256 nftId) external returns (bool);
    function buy(IERC721 nft, uint256 nftId) external;
    function cancelSale(IERC721 nft, uint256 nftId) external;

    function userMint(IUserMintNFT nft) external returns (uint256 id);

    function offer(IERC721 nft, uint256 nftId, uint256 price) external returns (uint256 offerId);
    function cancelOffer(IERC721 nft, uint256 nftId, uint256 offerId) external;
    function acceptOffer(IERC721 nft, uint256 nftId, uint256 offerId) external;

    function auction(IERC721 nft, uint256 nftId, uint256 startPrice, uint256 endBlock) external;
    function auctionWithPermit(ICakeNFT nft, uint256 nftId, uint256 startPrice, uint256 endBlock,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function cancelAuction(IERC721 nft, uint256 nftId) external;
    function checkAuction(IERC721 nft, uint256 nftId) external returns (bool);
    function bid(IERC721 nft, uint256 nftId, uint256 price) external returns (uint256 biddingId);
    function claim(IERC721 nft, uint256 nftId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ICakeStaker.sol";

interface ICakeOwnerVault {
    function cake() external returns (IERC20);
    function cakeStaker() external returns (ICakeStaker);
    function deposit(uint256 amount) external;
    function claim() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ICakeStaker.sol";

interface ICakeVault {
    function cake() external returns (IERC20);
    function cakeStaker() external returns (ICakeStaker);
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function claim() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./interfaces/ICakeDividend.sol";

contract CakeDividend is ICakeDividend {

    IERC20 override immutable public cake;
    ICakeStaker override immutable public cakeStaker;

    constructor(IERC20 _cake, ICakeStaker _cakeStaker) {
        cake = _cake;
        cakeStaker = _cakeStaker;
    }

    uint256 internal currentBalance = 0;
    uint256 override public totalStakedCakeBalance = 0;
    mapping(IERC721 => mapping(uint256 => uint256)) override public stakedCakeBalances;

    uint256 constant internal pointsMultiplier = 2**128;
    uint256 internal pointsPerShare = 0;
    mapping(IERC721 => mapping(uint256 => int256)) public pointsCorrection;
    mapping(IERC721 => mapping(uint256 => uint256)) public claimed;

    function updateBalance() internal {
        if (totalStakedCakeBalance > 0) {
            cakeStaker.leaveStaking(0);
            uint256 balance = cake.balanceOf(address(this));
            uint256 value = balance - currentBalance;
            if (value > 0) {
                pointsPerShare += value * pointsMultiplier / totalStakedCakeBalance;
                emit DistributeCake(msg.sender, value);
            }
            currentBalance = balance;
        }
    }

    function claimedCakeOf(IERC721 nft, uint256 nftId) override public view returns (uint256) {
        return claimed[nft][nftId];
    }

    function accumulativeCakeOf(IERC721 nft, uint256 nftId) override public view returns (uint256) {
        uint256 _pointsPerShare = pointsPerShare;
        if (totalStakedCakeBalance > 0) {
            uint256 balance = cakeStaker.pendingCake(0, address(this)) + cake.balanceOf(address(this));
            uint256 value = balance - currentBalance;
            if (value > 0) {
                _pointsPerShare += value * pointsMultiplier / totalStakedCakeBalance;
            }
            return uint256(int256(_pointsPerShare * stakedCakeBalances[nft][nftId]) + pointsCorrection[nft][nftId]) / pointsMultiplier;
        }
        return 0;
    }

    function claimableCakeOf(IERC721 nft, uint256 nftId) override external view returns (uint256) {
        return accumulativeCakeOf(nft, nftId) - claimed[nft][nftId];
    }

    function _accumulativeCakeOf(IERC721 nft, uint256 nftId) internal view returns (uint256) {
        return uint256(int256(pointsPerShare * stakedCakeBalances[nft][nftId]) + pointsCorrection[nft][nftId]) / pointsMultiplier;
    }

    function _claimableCakeOf(IERC721 nft, uint256 nftId) internal view returns (uint256) {
        return _accumulativeCakeOf(nft, nftId) - claimed[nft][nftId];
    }

    function claimCake(IERC721 nft, uint256 nftId) override external {
        updateBalance();
        uint256 claimable = _claimableCakeOf(nft, nftId);
        if (claimable > 0) {
            claimed[nft][nftId] += claimable;
            emit ClaimCake(nft, nftId, msg.sender, claimable);
            cake.transfer(nft.ownerOf(nftId), claimable);
            currentBalance -= claimable;
        }
    }

    function _stakeCake(IERC721 nft, uint256 nftId, uint256 amount) internal {
        updateBalance();
        cake.approve(address(cakeStaker), amount);
        cakeStaker.enterStaking(amount);
        totalStakedCakeBalance += amount;
        stakedCakeBalances[nft][nftId] += amount;
        pointsCorrection[nft][nftId] -= int256(pointsPerShare * amount);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./ICakeStaker.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICakeDividend {

    event DistributeCake(address indexed by, uint256 distributed);
    event ClaimCake(IERC721 indexed nft, uint256 indexed nftId, address indexed to, uint256 claimed);

    function cake() external returns (IERC20);
    function cakeStaker() external returns (ICakeStaker);
    function totalStakedCakeBalance() view external returns (uint256);
    function stakedCakeBalances(IERC721 nft, uint256 nftId) external view returns (uint256);
    
    function accumulativeCakeOf(IERC721 nft, uint256 nftId) external view returns (uint256);
    function claimedCakeOf(IERC721 nft, uint256 nftId) external view returns (uint256);
    function claimableCakeOf(IERC721 nft, uint256 nftId) external view returns (uint256);
    function claimCake(IERC721 nft, uint256 nftId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ICakeNFT is IERC721, IERC721Metadata, IERC721Enumerable {

    function deployer() external view returns (address);
    function version() external view returns (string memory);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function nonces(uint256 id) external view returns (uint256);

    function permit(
        address spender,
        uint256 id,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function mint() external returns (uint256 id);
    function massMint(uint256 count) external;
    function burn(uint256 id) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

interface ICakeStaker {
    function enterStaking(uint256 amount) external;
    function leaveStaking(uint256 amount) external;
    function pendingCake(uint256 pid, address user) external view returns (uint256);
    function userInfo(uint256 pid, address user) view external returns(uint256 amount, uint256 rewardDebt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IUserMintNFT is IERC721, IERC721Metadata, IERC721Enumerable {
    
    function deployer() external view returns (address);
    function storeAddress() external view returns (address);
    function version() external view returns (string memory);
    function mintPrice() view external returns (uint256);
    function maxMintCount() view external returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function nonces(uint256 id) external view returns (uint256);

    function permit(
        address spender,
        uint256 id,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function mint(address to) external returns (uint256 id);
    function burn(uint256 id) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

