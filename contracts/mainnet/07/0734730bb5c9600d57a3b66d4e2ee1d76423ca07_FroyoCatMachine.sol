/**
 *Submitted for verification at Etherscan.io on 2021-10-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

interface IFroyoCat {
    function adminMint(address[] calldata _toAddresses) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    
    function update(
        uint256 _nftId,
        address _owner,
        bool _claimed
    ) external;

    function get(uint256 _nftId)
        external
        view
        returns (
            address,
            bool,
            uint256
        );
}

interface IFroyoCatMachine {
    function claim(uint256 _nftId) external;

    function adminClaim(uint256 _nftId) external;
}

contract FroyoCatMachine is IFroyoCatMachine, Ownable {
    event Claim(address user, address to, uint256 nftId, uint256 time);

    IFroyoCat froyoCat;

    constructor(IFroyoCat _froyoCat) {
        froyoCat = _froyoCat;
    }

    function updateFroyoCat(IFroyoCat _froyoCat) external onlyOwner {
        froyoCat = _froyoCat;
    }

    function claim(uint256 _nftId) external override {
        address nftOwner;
        bool claimed;
        (nftOwner, claimed, ) = froyoCat.get(_nftId);
        require(_msgSender() == nftOwner, "Error: not owner of NFT");
        require(!claimed, "Error: NFT claimed already");

        froyoCat.transferFrom(address(this), nftOwner, _nftId);
        froyoCat.update(_nftId, nftOwner, true);

        emit Claim(_msgSender(), nftOwner, _nftId, block.timestamp);
    }

    function adminClaim(uint256 _nftId) external override onlyOwner {
        address nftOwner;
        bool claimed;
        (nftOwner, claimed, ) = froyoCat.get(_nftId);
        require(owner() != address(0), "Error: NFT invalid"); //NFT not exist
        require(!claimed, "Error: NFT claimed already");

        froyoCat.transferFrom(address(this), nftOwner, _nftId);
        froyoCat.update(_nftId, nftOwner, true);

        emit Claim(_msgSender(), nftOwner, _nftId, block.timestamp);
    }

    function get(uint256 _nftId)
        external
        view
        returns (
            address,
            bool,
            uint256
        )
    {
        return froyoCat.get(_nftId);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}