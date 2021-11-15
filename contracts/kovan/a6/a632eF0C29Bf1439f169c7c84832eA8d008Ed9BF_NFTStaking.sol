//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface INFTContract {
    function nfts(uint256 nftId)
        external
        view
        returns (
            uint256,
            string memory,
            string memory,
            uint256,
            bool,
            uint256
        );

    function nftOwners(uint256 nftId) external view returns (address);

    function mint(
        address _from,
        string memory _name,
        string memory _uri
    ) external;

    function burnNFT(uint256 _nftId) external;

    function transferNFT(address _to, uint256 _nftId) external;

    function getNFTLevelById(uint256 _nftId) external returns (uint256);

    function getNFTById(uint256 _nftId)
        external
        returns (
            uint256,
            string memory,
            string memory,
            uint256
        );

    function setNFTLevelUp(uint256 _nftId) external;

    function setNFTURI(uint256 _nftId, string memory _uri) external;

    function ownerOf(uint256 _nftId) external returns (address);

    function balanceOf(address _from) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INFTContract.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTStaking is Ownable {
    struct IStakedNFT {
        address nftOwner;
        uint256 power;
        uint256 lastStakedTime;
    }

    // nftId => IStackedNFT
    mapping(uint256 => IStakedNFT) public stakedNfts;

    INFTContract private nft_;
    IERC20 internal gfx_;

    uint256 private rateDivider_;

    event NFTStaked(
        uint256 nftId,
        address nftOwner,
        uint256 power,
        uint256 lastStakedTime
    );

    event GFXClaimed(
        uint256 nftId,
        address nftOwner,
        uint256 amount,
        uint256 lastStakedTime
    );

    event NFTClaimed(uint256 nftId, address nftOwner);

    constructor(address _nftAddress, address _gfxAddress) {
        nft_ = INFTContract(_nftAddress);
        gfx_ = IERC20(_gfxAddress);

        rateDivider_ = 30 * 24 * 60 * 60;
    }

    modifier _isNftOwner(uint256 _nftId) {
        require(
            msg.sender == stakedNfts[_nftId].nftOwner,
            "NFTStaking: Invalid NFT Owner"
        );
        _;
    }

    function updateRateDivider(uint256 _rate) public onlyOwner {
        rateDivider_ = _rate;
    }

    function stakeNFT(uint256 _nftId) public {
        address nftOwner = nft_.ownerOf(_nftId);
        require(nftOwner == msg.sender, "NFTStaking: Wrong NFT Owner");

        (, , , , , uint256 power) = nft_.nfts(_nftId);
        require(power > 0, "NFTStaking: NFT Power is below than 0");

        nft_.transferNFT(address(this), _nftId);

        IStakedNFT memory nft;
        nft.nftOwner = msg.sender;
        nft.power = power;
        nft.lastStakedTime = block.timestamp;

        stakedNfts[_nftId] = nft;

        emit NFTStaked(_nftId, nft.nftOwner, nft.power, nft.lastStakedTime);
    }

    function claimGFX(uint256 _nftId) public _isNftOwner(_nftId) {
        IStakedNFT memory nft = stakedNfts[_nftId];

        uint256 amount = getRewards(_nftId);
        gfx_.transferFrom(address(this), nft.nftOwner, amount);

        stakedNfts[_nftId].lastStakedTime = block.timestamp;

        emit GFXClaimed(
            _nftId,
            nft.nftOwner,
            amount,
            stakedNfts[_nftId].lastStakedTime
        );
    }

    function claimNFT(uint256 _nftId) public _isNftOwner(_nftId) {
        nft_.transferNFT(stakedNfts[_nftId].nftOwner, _nftId);

        emit NFTClaimed(_nftId, stakedNfts[_nftId].nftOwner);
    }

    function getRewards(uint256 _nftId) public view returns (uint256) {
        IStakedNFT memory nft = stakedNfts[_nftId];
        uint256 time = block.timestamp - nft.lastStakedTime;
        uint256 amount = (nft.power * time * 10**18) / rateDivider_;

        return amount;
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

