/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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


interface TokenInterface {
    function balanceOf(address account) external view returns (uint);
    function delegate(address delegatee) external;
    function transfer(address dst, uint rawAmount) external returns (bool);
}

interface IndexInterface {
    function master() external view returns (address);
}

interface InstaVestingInterface {
    function vestingAmount() external view returns (uint);
    function factory() external view returns (address);
}


contract InstaVestingFactory is Ownable {
    TokenInterface public constant token = TokenInterface(0x6f40d4A6237C257fff2dB00FA0510DeEECd303eb);
    IndexInterface public constant instaIndex = IndexInterface(0x2971AdFa57b20E5a416aE5a708A8655A9c74f723);
    InstaVestingFactory public constant instaVestingFactory = InstaVestingFactory(0x3b05a5295Aa749D78858E33ECe3b97bB3Ef4F029);

    constructor (address _owner) public {
        transferOwnership(_owner);
    }

    /**
     * @dev Throws if the sender not is Master Address from InstaIndex or owner
    */
    modifier isOwner {
        require(_msgSender() == instaIndex.master() || owner() == _msgSender(), "caller is not the owner or master");
        _;
    }

    function fundVestingContracts(
        address[] memory vestings
    ) public isOwner {
        uint _length = vestings.length;

        for (uint i = 0; i < _length; i++) {
            uint256 balanceOf = token.balanceOf(vestings[i]);
            uint256 vestingAmount = InstaVestingInterface(vestings[i]).vestingAmount();
            require(0x3b05a5295Aa749D78858E33ECe3b97bB3Ef4F029 == InstaVestingInterface(vestings[i]).factory(), "VestingFunder::fundVestingContracts: Other vesting contract");
            require(token.transfer(vestings[i], (vestingAmount - balanceOf)), "VestingFunder::fundVestingContracts: insufficient balance");
        }
    }

    function withdraw() public isOwner {
        token.transfer(owner(), token.balanceOf(address(this)));
    }
}