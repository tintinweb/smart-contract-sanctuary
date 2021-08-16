/**
 *Submitted for verification at BscScan.com on 2021-08-16
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-06
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
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

interface IMerkleDistributor {
    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index) external view returns (bool);
    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(uint256 index, address account) external;
    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address account);
}

interface ThunderBnbToken {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function balanceOf(address _owner) external returns (uint256 balance);
}

contract ThunderBnbAirdrop is Ownable, IMerkleDistributor {
    mapping(uint256 => uint256) private claimedBitMap;

    address public token;
    uint256 public amount = 30 ether;

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
        require(!isClaimed(index), 'Airdrop already claimed.');

        // Mark it claimed and send the token.
        _setClaimed(index);

        require(ThunderBnbToken(token).transfer(account, amount), 'Transfer failed.');

        emit Claimed(index, account);
    }

    function setAmount(uint256 _amount) public onlyOwner returns (bool) {
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
        ThunderBnbToken(_token).transfer(_owner, _amount);
    }
}