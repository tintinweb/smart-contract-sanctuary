/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-12
*/

// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]



pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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


// File ThoreumAirdrop.sol



pragma solidity >=0.6.0 <0.8.0;


// Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleDistributor {
    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index) external view returns (bool);
    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(uint256 index, address account) external;
    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address account);
}

interface IThoreumToken {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function balanceOf(address _owner) external returns (uint256 balance);
}

contract Whitelisted is Ownable {
    bool isWhitelistStarted = false;

    mapping(address => uint8) public whitelist;

    modifier onlyWhitelisted {
        require(isWhitelisted(msg.sender));
        _;
    }

    function getWhitelistedZone(address _purchaser) public view returns (uint8) {
        return whitelist[_purchaser] > 0 ? whitelist[_purchaser] : 0;
    }

    function isWhitelisted(address _purchaser) public view returns (bool){
        return whitelist[_purchaser] > 0;
    }

    function joinWhitelist(address _purchaser, uint8 _zone) public {
        require(isWhitelistStarted == true, "Whitelist not started");
        whitelist[_purchaser] = _zone;
    }

    function deleteFromWhitelist(address _purchaser) public onlyOwner {
        whitelist[_purchaser] = 0;
    }

    function addToWhitelist(address[] memory purchasers, uint8 _zone) public onlyOwner {
        for (uint256 i = 0; i < purchasers.length; i++) {
            whitelist[purchasers[i]] = _zone;
        }
    }

    function startWhitelist(bool _status) public onlyOwner {
        isWhitelistStarted = _status;
    }
}

contract ThoreumAirdrop is Ownable, IMerkleDistributor, Whitelisted {
    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    address public token;
    uint256 public amount = 30 ether;
    uint256 public MAX_AMOUNT = 1000 ether;

    constructor(
        address _token,
        uint256 _amount
    ) public {
        token = _token;
        amount = _amount;
    }

    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(uint256 index, address account) external override {
        require(isWhitelisted(msg.sender),"Only whitelist");
        require(!isClaimed(index), 'ThoreumAirdrop:: Airdrop already claimed.');

        // Mark it claimed and send the token.
        _setClaimed(index);

        require(IThoreumToken(token).transfer(account, amount), 'ThoreumAirdrop:: Transfer failed.');

        emit Claimed(index, account);
    }

    function setAmount(uint256 _amount) public onlyOwner returns (bool) {
        require(_amount <= MAX_AMOUNT, 'ThoreumAirdrop:: Set _amount failed.');
        amount = _amount;
        return true;
    }

    function setToken(address _token) public onlyOwner returns (bool) {
        token = _token;
        return true;
    }

    function recoverLostBNB() public onlyOwner {
        address payable _owner = msg.sender;
        _owner.transfer(address(this).balance);
    }

    function recoverLostToken(address _token, uint256 _amount) public onlyOwner {
        address payable _owner = msg.sender;
        IThoreumToken(_token).transfer(_owner, _amount);
    }
}