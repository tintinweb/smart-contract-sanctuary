/**
 *Submitted for verification at BscScan.com on 2021-10-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: mod by zero");
        return a % b;
    }
}

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

interface Energy{
  function balanceOf(address user) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function totalSupply() external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract Energy_PreSale is Ownable {
	using SafeMath for uint256;

    Energy public energy;

    // Info of each user.
    struct UserInfo {
        uint256[3] totalBuy;
        address referrer;
        uint256 refCnt;
        uint256 refTotal;
    }

    mapping (address => UserInfo) public userInfo;

    uint256[] public PRESALE_MIN = [0.1 ether, 0.2 ether, 0.3 ether];
    uint256[] public PRESALE_MAX = [10 ether, 15 ether, 20 ether];
    uint256[] public PRESALE_TOTAL = [1000000 ether, 700000 ether, 300000 ether];
    
    // uint256 public PRESALE_DURATION = 3 days;
    uint256 public PRESALE_DURATION = 2 days;
    uint256 public PRESALE_REFERRAL = 25;
    uint256 public PERCENT_DIVIDER  = 1000;

    uint256[3] public PRESALE_START;
    uint256[3] public PRESALE_END;
    uint256[3] public PRESALE_PRICE;
    uint256[3] public PRESALE_SOLD;

    address payable projectWallet;    

    event Buy(address indexed user, uint256 BNBAmount, uint256 EnergyAmount, uint256 index );

    constructor(address payable projectAddr, address energyAddress, uint256 startDate, uint256 price1, uint256 price2, uint256 price3) {
        require(projectAddr != address(0),"unvalid project address");
        require(energyAddress != address(0),"unvalid energy address");
        require(startDate > 0 && startDate > block.timestamp ,"wrong start date");
        require(price1 > 0 && price2 > 0 && price3 > 0 ,"wrong start date");

        projectWallet = projectAddr;
		energy = Energy(energyAddress);

        PRESALE_START[0] = startDate;
        PRESALE_END[0]   = startDate.add(PRESALE_DURATION);
        PRESALE_START[1] = startDate.add(PRESALE_DURATION);
        PRESALE_END[1]   = startDate.add(PRESALE_DURATION.mul(2));
        PRESALE_START[2] = startDate.add(PRESALE_DURATION.mul(2));
        PRESALE_END[2]   = startDate.add(PRESALE_DURATION.mul(3));

        PRESALE_PRICE[0] = price1;
        PRESALE_PRICE[1] = price2;
        PRESALE_PRICE[2] = price3;

	}

    function buy(uint256 index, address referrer) public payable {
        require( index < 3,"unvalid index");
        require( PRESALE_END[index]   >= block.timestamp ,"Presale finished");
        require( PRESALE_START[index] <= block.timestamp ,"Presale does not start yet");
        require( msg.value >= PRESALE_MIN[index] ,"amount is less than the minimum");
        
        uint256 BNBAmount = msg.value;
        require( BNBAmount.add(userInfo[msg.sender].totalBuy[index])  <= PRESALE_MAX[index] ,"Total buy is more than the maximum");

        uint256 energyAmount = BNBAmount.div(PRESALE_PRICE[index]).mul(10**18);
        require( energyAmount <= PRESALE_TOTAL[index].sub(PRESALE_SOLD[index]) ,"all tokens sold");
        
        energy.transfer(msg.sender,energyAmount);

        //referral
        if(getUserTotalBuy(referrer) > 0 && userInfo[msg.sender].referrer == address(0)){
            userInfo[msg.sender].referrer = referrer;
            userInfo[referrer].refCnt++;
        }

        if(userInfo[msg.sender].referrer != address(0)){
            uint256 refAmount = BNBAmount.mul(PRESALE_REFERRAL).div(PERCENT_DIVIDER);
            userInfo[referrer].refTotal = userInfo[referrer].refTotal.add(refAmount);
            payable(userInfo[msg.sender].referrer).transfer(refAmount);
        }

        projectWallet.transfer(address(this).balance);

        userInfo[msg.sender].totalBuy[index] = userInfo[msg.sender].totalBuy[index].add(BNBAmount);
        PRESALE_SOLD[index] = PRESALE_SOLD[index].add(energyAmount);
        emit Buy(msg.sender, BNBAmount, energyAmount, index);
    }

    function getUserTotalBuy(address user) public view returns(uint256){
        return userInfo[user].totalBuy[0].add(userInfo[user].totalBuy[1]).add(userInfo[user].totalBuy[2]);
    }

    function getUserRefStats(address user) public view returns(uint256, uint256){
        return (
            userInfo[user].refCnt,
            userInfo[user].refTotal
            );
    }

    function getPreSaleInfo() public view returns(uint256[3] memory, uint256[3] memory, uint256[3] memory){
        return (
            PRESALE_START,
            PRESALE_END,
            PRESALE_PRICE
            );
    }

    function getPreSaleRemains() public view returns(uint256, uint256, uint256){
        return (
            PRESALE_TOTAL[0].sub(PRESALE_SOLD[0]),
            PRESALE_TOTAL[1].sub(PRESALE_SOLD[1]),
            PRESALE_TOTAL[2].sub(PRESALE_SOLD[2])
            );
    }

    function end(address masterChef) external onlyOwner {
        require( block.timestamp > PRESALE_END[2],"not yet");


        uint256 contractEnergyBalance = energy.balanceOf(address(this));
		if (contractEnergyBalance > 0) {
            energy.transfer(masterChef,contractEnergyBalance);
        }

        uint256 contractBalance = address(this).balance;
		if (contractBalance > 0) {
            projectWallet.transfer(contractBalance);
        }
    }

}

/* © 2021 by S&S8712943. All rights reserved. */