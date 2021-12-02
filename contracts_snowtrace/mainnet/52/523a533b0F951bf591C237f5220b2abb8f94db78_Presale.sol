/**
 *Submitted for verification at snowtrace.io on 2021-12-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

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

interface SHARK_Interface {
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface MIM_Interface {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Presale is Ownable {
    address SHARK = 0x01d0D7Eb72E996B62651C60Fe70b88ca07Bb8e92;
    SHARK_Interface public shark = SHARK_Interface(SHARK);
    
    address MIM = 0x130966628846BFd36ff31a822705796e8cb8C18D;
    MIM_Interface public mim = MIM_Interface(MIM);

    mapping(address => uint) allocSize;
    mapping(address => bool) isWhitelisted;
    mapping(address => bool) hasParticipated;

    function addWhitelist(address _user) public onlyOwner {
        isWhitelisted[_user] = true;
    }

    function userWhitelisted(address _user) public view returns (bool) {
        return isWhitelisted[_user];
    }

    function hasBought(address _user) public view returns (bool) {
        return hasParticipated[_user];
    }

    function participate(uint _amount) public {
        require(isWhitelisted[msg.sender], "You are not whitelisted.");
        require(_amount <= 2_000e18, "Incorrect value.");
        require(hasParticipated[msg.sender] == false, "You already participated");

        mim.transferFrom(msg.sender, 0xd370a97ddaB6d61F0DB59f70E0165DFFB7914ADb, _amount);
        shark.approve(msg.sender, allocSize[msg.sender]);

        allocSize[msg.sender] = _amount;
        hasParticipated[msg.sender] = true;
    }

    function send(address _user) public onlyOwner {
        shark.transfer(_user, allocSize[_user]/2);
        allocSize[msg.sender] = 0;
    }
}