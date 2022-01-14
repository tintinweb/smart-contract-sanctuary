/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IGenArtInterface {
    function getMaxMintForMembership(uint256 _membershipId)
        external
        view
        returns (uint256);

    function getMaxMintForOwner(address owner) external view returns (uint256);

    function upgradeGenArtTokenContract(address _genArtTokenAddress) external;

    function setAllowGen(bool allow) external;

    function genAllowed() external view returns (bool);

    function isGoldToken(uint256 _membershipId) external view returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _membershipId) external view returns (address);
}

interface IGenArt {
    function getTokensByOwner(address owner)
        external
        view
        returns (uint256[] memory);

    function ownerOf(uint256 tokenId) external view returns (address);

    function balanceOf(address owner) external view returns (uint256);

    function isGoldToken(uint256 _tokenId) external view returns (bool);
}

interface IGenArtAirdrop {
    function getAllowedMintForMembership(
        uint256 _collectionId,
        uint256 _membershipId
    ) external view returns (uint256);
}

interface IGenArtDrop {
    function getAllowedMintForMembership(uint256 _group, uint256 _membershipId)
        external
        view
        returns (uint256);
}

contract GenArtTokenAirdrop is Ownable {
    address genArtTokenAddress;
    address genArtMembershipAddress;

    uint256 tokensPerMint = 213 * 1e18;
    uint256 endBlock;
    address genArtAirdropAddress;
    address genArtDropAddress;

    uint256[] airdropCollections = [1, 2];
    uint256[] dropCollectionGroups = [1, 2, 3, 4, 5, 6, 7, 8, 9];

    mapping(uint256 => bool) membershipClaims;
    event Claimed(address account, uint256 membershipId, uint256 amount);

    constructor(
        address genArtMembershipAddress_,
        address genArtTokenAddress_,
        address genArtAirdropAddress_,
        address genArtDropAddress_,
        uint256 endBlock_
    ) {
        genArtTokenAddress = genArtTokenAddress_;
        genArtMembershipAddress = genArtMembershipAddress_;
        genArtAirdropAddress = genArtAirdropAddress_;
        genArtDropAddress = genArtDropAddress_;
        endBlock = endBlock_;
    }

    function claimAllTokens() public {
        require(
            block.number < endBlock,
            "GenArtTokenAirdrop: token claiming window has ended"
        );
        uint256[] memory memberships = IGenArt(genArtMembershipAddress)
            .getTokensByOwner(msg.sender);
        require(
            memberships.length > 0,
            "GenArtTokenAirdrop: sender does not own memberships"
        );
        uint256 airdropTokenAmount = 0;
        for (uint256 i = 0; i < memberships.length; i++) {
            airdropTokenAmount += getAirdropTokenAmount(memberships[i]);
            membershipClaims[memberships[i]] = true;
            emit Claimed(msg.sender, memberships[i], airdropTokenAmount);
        }
        require(
            airdropTokenAmount > 0,
            "GenArtTokenAirdrop: no tokens to claim"
        );
        IERC20(genArtTokenAddress).transfer(msg.sender, airdropTokenAmount);
    }

    function claimTokens(uint256 membershipId) public {
        require(
            !membershipClaims[membershipId],
            "GenArtTokenAirdrop: tokens already claimed"
        );
        require(
            block.number < endBlock,
            "GenArtTokenAirdrop: token claiming window has ended"
        );
        require(
            IGenArt(genArtMembershipAddress).ownerOf(membershipId) ==
                msg.sender,
            "GenArtTokenAirdrop: sender is not owner of membership"
        );

        uint256 airdropTokenAmount = getAirdropTokenAmount(membershipId);

        require(
            airdropTokenAmount > 0,
            "GenArtTokenAirdrop: no tokens to claim"
        );
        IERC20(genArtTokenAddress).transfer(msg.sender, airdropTokenAmount);
        emit Claimed(msg.sender, membershipId, airdropTokenAmount);
        membershipClaims[membershipId] = true;
    }

    function getAirdropTokenAmountAccount(address account)
        public
        view
        returns (uint256)
    {
        uint256[] memory memberships = IGenArt(genArtMembershipAddress)
            .getTokensByOwner(account);
        uint256 airdropTokenAmount = 0;
        for (uint256 i = 0; i < memberships.length; i++) {
            airdropTokenAmount += getAirdropTokenAmount(memberships[i]);
        }

        return airdropTokenAmount;
    }

    function getAirdropTokenAmount(uint256 membershipId)
        public
        view
        returns (uint256)
    {
        if (membershipClaims[membershipId]) {
            return 0;
        }

        bool isGoldToken = IGenArt(genArtMembershipAddress).isGoldToken(
            membershipId
        );
        uint256 tokenAmount = 0;
        for (uint256 i = 0; i < airdropCollections.length; i++) {
            uint256 remainingMints = IGenArtAirdrop(genArtAirdropAddress)
                .getAllowedMintForMembership(
                    airdropCollections[i],
                    membershipId
                );

            uint256 mints = (isGoldToken ? 5 : 1) - remainingMints;
            tokenAmount = tokenAmount + (mints * tokensPerMint);
        }

        for (uint256 i = 0; i < dropCollectionGroups.length; i++) {
            uint256 remainingMints = IGenArtDrop(genArtAirdropAddress)
                .getAllowedMintForMembership(
                    dropCollectionGroups[i],
                    membershipId
                );

            uint256 mints = (isGoldToken ? 5 : 1) - remainingMints;
            tokenAmount = tokenAmount + (mints * tokensPerMint);
        }

        return tokenAmount;
    }

    /**
     * @dev Function to receive ETH
     */
    receive() external payable virtual {}

    function withdrawTokens(uint256 _amount, address _to) public onlyOwner {
        IERC20(genArtTokenAddress).transfer(_to, _amount);
    }

    function withdraw(uint256 value) public onlyOwner {
        address _owner = owner();
        payable(_owner).transfer(value);
    }
}