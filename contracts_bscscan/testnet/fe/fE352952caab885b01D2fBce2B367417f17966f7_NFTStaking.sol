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
        uint256 nftId;
        address nftOwner;
        string nftImage;
        uint256 nftPower;
        uint256 lastStakedTime;
    }

    // (address nftOwner => IStakedNFT[] nfts)
    mapping(address => IStakedNFT[]) public stakedNfts;
    // (address nftOwner => uint256 nftsCount)
    mapping(address => uint256) public stakedNftsCount;
    // (uint256 nftId => address nftOwner)
    mapping(uint256 => address) public nftOwners;

    INFTContract private nft_;
    IERC20 private gfx_;

    uint256 private rate_;
    uint256 private secondsToMonth_;

    event NewNFTStaked(
        uint256 nftId,
        address nftOwner,
        string nftImage,
        uint256 nftPower,
        uint256 lastStakedTime
    );

    event ClaimedNFT(uint256 nftId, address nftOwner);

    event ClaimedGFX(address nftOwner, uint256 amount);

    constructor() {
        rate_ = 1;
        secondsToMonth_ = 60 * 60 * 24 * 30;
    }

    /**
     * @notice Initalize Interfaces
     *
     * @param _nftContractAddress NFTContract Address
     * @param _gfxContractAddress ERC20 GFX Contract Address
     */
    function initialize(
        address _nftContractAddress,
        address _gfxContractAddress
    ) public {
        nft_ = INFTContract(_nftContractAddress);
        gfx_ = IERC20(_gfxContractAddress);
    }

    /**
     * @notice Calculate GFX Rewards Amount
     *
     * @param _power NFT Power
     * @param _time NFT Last Staked Time
     */
    function calculateRewardsAmount(uint256 _power, uint256 _time)
        internal
        view
        returns (uint256)
    {
        uint256 time = block.timestamp - _time;
        uint256 amount = (_power * time * (10**18)) / (secondsToMonth_ * rate_);

        return amount;
    }

    /**
     * @notice Update Claim Rate
     *
     * @param _rate New Claim Rate
     */
    function setClaimRate(uint256 _rate) public onlyOwner {
        rate_ = _rate;
    }

    /**
     * @notice Stake NFT
     *
     * @param _nftId NFT ID
     */
    function stakeNFT(uint256 _nftId) public {
        address nftOwner = nft_.ownerOf(_nftId);
        require(msg.sender == nftOwner, "NFTStaking: Invalid NFTOwner");

        (, , string memory uri, uint256 level, , uint256 power) =
            nft_.nfts(_nftId);
        require(power > 0, "NFTStaking: No Powered NFT");
        require(level > 4, "NFTStaking: NFT Level is not enough to stake");

        IStakedNFT memory nft;
        nft.nftId = _nftId;
        nft.nftOwner = msg.sender;
        nft.nftImage = uri;
        nft.nftPower = power;
        nft.lastStakedTime = block.timestamp;

        stakedNfts[msg.sender].push(nft);
        stakedNftsCount[msg.sender]++;
        nftOwners[_nftId] = msg.sender;

        nft_.transferNFT(address(this), _nftId);

        emit NewNFTStaked(_nftId, msg.sender, uri, power, nft.lastStakedTime);
    }

    /**
     * @notice Get GFX Rewards Amount by NFT ID
     *
     * @param _nftId NFT ID
     */
    function getRewardsByNftId(uint256 _nftId) public view returns (uint256) {
        address nftOwner = nftOwners[_nftId];
        require(nftOwner != address(0), "NFTStaking: Invalid NFT ID");

        uint256 nftIndex;
        for (uint256 i = 0; i < stakedNfts[nftOwner].length; i++) {
            if (stakedNfts[nftOwner][i].nftId == _nftId) {
                nftIndex = i;
            }
        }

        uint256 amount =
            calculateRewardsAmount(
                stakedNfts[nftOwner][nftIndex].nftPower,
                stakedNfts[nftOwner][nftIndex].lastStakedTime
            );

        return amount;
    }

    /**
     * @notice Get GFX Rewards Amount by NFT Owner
     *
     * @param _owner NFT Owner
     */
    function getRewardsByOwner(address _owner) public view returns (uint256) {
        require(_owner != address(0), "NFTStaking: Invalid Address");
        if (stakedNfts[_owner].length == 0) {
            return uint256(0);
        }

        uint256 amount = 0;
        for (uint256 i = 0; i < stakedNfts[_owner].length; i++) {
            uint256 nftAmount =
                calculateRewardsAmount(
                    stakedNfts[_owner][i].nftPower,
                    stakedNfts[_owner][i].lastStakedTime
                );
            amount += nftAmount;
        }

        return amount;
    }

    /**
     * @notice Claim All Staked NFTs
     */
    function claimAllNfts() public {
        IStakedNFT[] memory nfts = stakedNfts[msg.sender];
        require(nfts.length > 0, "NFTStaking: No staked nfts");

        uint256 amount = getRewardsByOwner(msg.sender);

        for (uint256 i = 0; i < nfts.length; i++) {
            nft_.transferNFT(nfts[i].nftOwner, nfts[i].nftId);

            delete nftOwners[nfts[i].nftId];
            emit ClaimedNFT(nfts[i].nftId, nfts[i].nftOwner);
        }

        gfx_.transfer(msg.sender, amount);

        stakedNftsCount[msg.sender] = 0;
        delete stakedNfts[msg.sender];
    }

    /**
     * @notice Claim staked nft by Id
     */
    function claimNFTById(uint256 _nftId) public {
        address nftOwner = nftOwners[_nftId];

        require(nftOwner == msg.sender, "NFTStaking: Invalid NFT Owner");

        nft_.transferNFT(nftOwner, _nftId);
        emit ClaimedNFT(_nftId, nftOwner);
    }

    /**
     * @notice Claim GFX awards
     */
    function claimGFXRewards() public {
        uint256 amount = getRewardsByOwner(msg.sender);
        gfx_.transfer(msg.sender, amount);

        for (uint256 i = 0; i < stakedNfts[msg.sender].length; i++) {
            stakedNfts[msg.sender][i].lastStakedTime = block.timestamp;
        }

        emit ClaimedGFX(msg.sender, amount);
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

