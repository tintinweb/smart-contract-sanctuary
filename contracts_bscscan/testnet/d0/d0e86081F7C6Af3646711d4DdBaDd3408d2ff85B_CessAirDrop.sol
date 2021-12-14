/**
 *Submitted for verification at BscScan.com on 2021-12-14
*/

pragma solidity ^0.5.12;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract CessAirDrop is Ownable{
    mapping(address => uint256) airBalance;
    mapping(address => uint256) public airTime;

    uint256 public airAmount = 10000 ether;
    address public core = 0x6C96BBE57E71a0497A5A87005c68d72b1A679258;
    IERC20 public cess = IERC20(0x726370eCA31d3E8816AA39DcCe6CeCc1dF067517);

    modifier onlyCore() {
        require(msg.sender == core, "caller is not the core");
        _;
    }

    /// Modify the number of airdrops per drop
    function changeAirAmount(uint256 amount) public onlyOwner {
        require(amount != 0, "The value cannot be zero");
        airAmount = amount;
    }


    function airDropOne(address account) public onlyOwner {
        require(airTime[account] == 0, "The address has been airdropped");
        airTime[account] = block.timestamp;
        airBalance[account] = airAmount;
    }

    function airDropMul(address[] memory accounts) public onlyOwner {
        for (uint256 index = 0; index < accounts.length; index++) {
            address acc = accounts[index];
            if (airTime[acc] == 0) {
                airTime[acc] = block.timestamp;
                airBalance[acc] = airAmount;
            }
        }
    }

    function cancel(address[] memory accounts) public onlyOwner {
        uint256 nowTime = block.timestamp;
        for (uint256 index = 0; index < accounts.length; index++) {
            address acc = accounts[index];
            // 180 * 24 * 3600 = 15552000  180 days
            if (nowTime - airTime[acc] > 15552000) {
                airBalance[acc] = 0;
            }
        }
    }
 
    // 查询空投的余额
    function balanceOf(address account) view public returns(uint256) {
        return airBalance[account];
    }

    function airTransfer(address user, uint256 amount) public onlyCore returns(bool) {
        require(amount <= airBalance[user], "aridrop value insufficient");
        airBalance[user] = airBalance[user] - amount;
        cess.transfer(core, amount);
        return true;
    }
}