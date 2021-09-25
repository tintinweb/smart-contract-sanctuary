/**
 *Submitted for verification at Etherscan.io on 2021-09-25
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]



pragma solidity ^0.8.0;

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


// File contracts/WickedStaking.sol


pragma solidity ^0.8.0;

abstract contract TWC {
    function ownerOf(uint256 tokenId) public view virtual returns (address);

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256);

    function balanceOf(address owner) external view virtual returns (uint256 balance);

    function setApprovalForAll(address operator, bool _approved) external virtual;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual;
}

abstract contract TWS {
    function ownerOf(uint256 tokenId) public view virtual returns (address);

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256);

    function balanceOf(address owner) external view virtual returns (uint256 balance);

    function setApprovalForAll(address operator, bool _approved) external virtual;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual;
}

abstract contract WickedCraniumsComic {
    function ownerOf(uint256 tokenId) external view virtual returns (address);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view virtual returns (uint256);

    function balanceOf(address owner) external view virtual returns (uint256 balance);

    function safeMint(address to) public virtual;
}

abstract contract WickedCraniumsXHaylos {
    function ownerOf(uint256 tokenId) external view virtual returns (address);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view virtual returns (uint256);

    function balanceOf(address owner) external view virtual returns (uint256 balance);

    function safeMint(address to) public virtual;
}

contract WickedStaking is Ownable {
    TWC private twc = TWC(0x85f740958906b317de6ed79663012859067E745B);
    TWS private tws = TWS(0x45d8f7Db9b437efbc74BA6a945A81AaF62dcedA7);
    WickedCraniumsComic private comic = WickedCraniumsComic(0xA932DaC13BED512aaa12975f7aD892afB120022f);
    WickedCraniumsXHaylos private haylos = WickedCraniumsXHaylos(0xB8bD00aA3a8fa212E0654c7382c1c7936c9728e6);

    mapping(address => uint256) private pagesUnredeemed;
    mapping(address => uint256[]) private addressToCraniumsStaked;
    mapping(address => uint256[]) private addressToStallionsStaked;
    mapping(address => uint256) private unstakedIndex;

    bool public isStakingActive = false;
    bool public areComicPagesRedeemable = false;
    bool public isUnstakingActive = false;

    constructor() {}

    function flipStakingState() public onlyOwner {
        isStakingActive = !isStakingActive;
    }

    function flipComicRedeemableState() public onlyOwner {
        areComicPagesRedeemable = !areComicPagesRedeemable;
    }

    function flipUnstakingState() public onlyOwner {
        isUnstakingActive = !isUnstakingActive;
    }

    function stake(uint256[] memory craniumIds, uint256[] memory stallionIds) public {
        require(isStakingActive, "stake: staking must be active");
        require(craniumIds.length == stallionIds.length, "stake: Total number of Craniums staked must match the total number of Stallions staked.");
        require(craniumIds.length >= 1, "stake: 1 or more {Cranium, Stallion} pairs must be staked.");

        for (uint256 i = 0; i < craniumIds.length; i++) {
            require(twc.ownerOf(craniumIds[i]) == msg.sender, "stake: msg.sender must be the owner of all Craniums staked.");
        }

        for (uint256 i = 0; i < stallionIds.length; i++) {
            require(tws.ownerOf(stallionIds[i]) == msg.sender, "stake: msg.sender must be the owner of all Stallions staked.");
        }

        // twc.setApprovalForAll(address(this), true);
        // tws.setApprovalForAll(address(this), true);

        for (uint256 i = 0; i < craniumIds.length; i++) {
            twc.transferFrom(msg.sender, address(this), craniumIds[i]);
        }

        for (uint256 i = 0; i < stallionIds.length; i++) {
            tws.transferFrom(msg.sender, address(this), stallionIds[i]);
        }

        for (uint256 i = 0; i < craniumIds.length; i++) {
            haylos.safeMint(msg.sender);
        }

        pagesUnredeemed[msg.sender] += craniumIds.length;

        for (uint256 i = 0; i < craniumIds.length; i++) {
            addressToCraniumsStaked[msg.sender].push(craniumIds[i]);
            addressToStallionsStaked[msg.sender].push(stallionIds[i]);
        }
    }

    function redeemComicPages(uint256 pagesToRedeem) public {
        require(areComicPagesRedeemable, "redeeming comic pages is not active");
        require(pagesToRedeem > 0, "redeemComicPages: Can only request to redeem > 0 pages");
        require(pagesToRedeem <= pagesUnredeemed[msg.sender], "redeemComicPages: pages to redeem must be <= pages unredeemed for this address");

        for (uint256 i = 0; i < pagesToRedeem; i++) {
            comic.safeMint(msg.sender);
        }

        pagesUnredeemed[msg.sender] -= pagesToRedeem;
    }

    function redeemAllComicPages() public {
        require(areComicPagesRedeemable, "redeeming comic pages is not active");
        require(pagesUnredeemed[msg.sender] > 0, "redeemAllComicPages: pages unredeemed for this address should be > 0");

        uint256 pagesToRedeem = pagesUnredeemed[msg.sender];

        for (uint256 i = 0; i < pagesToRedeem; i++) {
            comic.safeMint(msg.sender);
        }

        pagesUnredeemed[msg.sender] -= pagesToRedeem;
    }

    function unstakeAll() public {
        require(isUnstakingActive, "unstaking is not active");
        require(addressToCraniumsStaked[msg.sender].length > 0, "unstakeAll: craniums staked for this address should be > 0");
        require(unstakedIndex[msg.sender] < addressToCraniumsStaked[msg.sender].length, "unstakeAll: unstake index must be less than total staked");

        uint256[] memory craniumsToUnstake = addressToCraniumsStaked[msg.sender];
        uint256[] memory stallionsToUnstake = addressToStallionsStaked[msg.sender];

        for (uint256 i = unstakedIndex[msg.sender]; i < craniumsToUnstake.length; i++) {
            twc.transferFrom(address(this), msg.sender, craniumsToUnstake[i]);
            tws.transferFrom(address(this), msg.sender, stallionsToUnstake[i]);
        }

        unstakedIndex[msg.sender] += craniumsToUnstake.length;
    }

    function unstakeSome(uint256 totalToUnstake) public {
        require(isUnstakingActive, "unstaking is not active");
        require(totalToUnstake > 0, "cannot unstake 0 or less pairs");
        require(
            totalToUnstake <= addressToCraniumsStaked[msg.sender].length - unstakedIndex[msg.sender],
            "unstakeSome: totalToUnstake <= total staked - unstakedIndex"
        );

        uint256[] memory craniumsStaked = addressToCraniumsStaked[msg.sender];
        uint256[] memory stallionsStaked = addressToStallionsStaked[msg.sender];

        for (uint256 i = unstakedIndex[msg.sender]; i < unstakedIndex[msg.sender] + totalToUnstake; i++) {
            twc.transferFrom(address(this), msg.sender, craniumsStaked[i]);
            tws.transferFrom(address(this), msg.sender, stallionsStaked[i]);
        }

        unstakedIndex[msg.sender] += totalToUnstake;
    }
}