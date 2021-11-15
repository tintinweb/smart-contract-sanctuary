// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IMMPIndustries {
    function mint(address _to, uint32 _assetCode) external returns (uint256);
}

contract ClaimAirdrop2_2 is Ownable {
    uint32 internal constant NOT_CLAIM = 0;
    uint32 internal constant CLAIMED = 1;

    uint32 internal constant NOT_CLAIMABLE = 0;
    uint32 internal constant CLAIMABLE = 1;

    struct ClaimedInfo {
        uint32 tier;
        uint32 hasClaimed;
        uint32 claimable;
    }

    mapping(address => ClaimedInfo) public claimedInfos;
    mapping(uint256 => uint32) private tiers;

    uint32[] private assetCodes;
    uint256 public startClaimTime;

    IMMPIndustries public industries;

    constructor(
        IMMPIndustries _industries,
        uint256 _startClaimTime,
        uint32 assetCodeTier1,
        uint32 assetCodeTier2,
        uint32 assetCodeTier3
    ) {
        industries = _industries;
        startClaimTime = _startClaimTime;
        assetCodes = [assetCodeTier1, assetCodeTier2, assetCodeTier3];
    }

    function claim() external returns (uint256) {
        require(block.timestamp > startClaimTime, "Too early to claim");

        address senderAddress = _msgSender();
        require(claimedInfos[senderAddress].claimable == CLAIMABLE, "You are not allow to claim");
        require(claimedInfos[senderAddress].hasClaimed == NOT_CLAIM, "Already claimed");

        uint32 tier = claimedInfos[senderAddress].tier;

        claimedInfos[senderAddress].hasClaimed = CLAIMED;
        uint256 tokenId = industries.mint(senderAddress, getAssetCodeTier(tier));

        tiers[tokenId] = tier;
        return tokenId;
    }

    function canClaim(address _address) external view returns (bool) {
        return (
            claimedInfos[_address].hasClaimed == NOT_CLAIM &&
            claimedInfos[_address].claimable == CLAIMABLE
        );
    }

    function getTier(address _address) external view returns (uint256) {
        return claimedInfos[_address].tier;
    }

    function getAssetCodeTier(uint32 _tier) public view returns (uint32) {
        require(_tier > 0 && _tier <= 3, "Tier must be between 1-3");
        return assetCodes[_tier - 1];
    }

    function getAssetCodeToken(uint256 _tokenId) external view returns (uint32) {
        return getAssetCodeTier(tiers[_tokenId]);
    }

    function setTierAsset(uint32 _tier, uint32 _assetCode) external onlyOwner {
        require(_tier > 0 && _tier <= 3, "Tier must be between 1-3");
        require(_assetCode >= 10000 || _assetCode < 100000, "Code is not valid");

        assetCodes[_tier - 1] = _assetCode;
    }

    function setStartClaimTime(uint256 _startClaimTime) external onlyOwner {
        startClaimTime = _startClaimTime;
    }

    function allowClaim(address[] calldata _dests, uint32 tier) external onlyOwner {
        ClaimedInfo memory info = ClaimedInfo({
            tier: tier,
            hasClaimed: NOT_CLAIM,
            claimable: CLAIMABLE
        });

        uint256 i = 0;
        while (i < _dests.length) {
            address _address = _dests[i];
            require(
                claimedInfos[_address].claimable == NOT_CLAIMABLE,
                string(abi.encodePacked("Address index ", uint2str(i), " has already allowed"))
            );

            claimedInfos[_address] = info;
            i++;
        }
    }

    // support error string
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
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

