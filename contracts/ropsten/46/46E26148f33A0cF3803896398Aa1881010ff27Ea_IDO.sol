/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-18
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
interface IdexRouter02{
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] memory path)
        external view
        returns (uint[] memory amounts);
}
interface relationship {
    function father(address _son) external view returns(address);
    function otherCallSetRelationship(address _son, address _father) external;
    function getFather(address _addr) external view returns(address);
    function getGrandFather(address _addr) external view returns(address);
}
interface ISAGToken {
    function walletAGate() external view returns(uint256);
    function walletBGate() external view returns(uint256);
    function fatherGate() external view returns(uint256);
    function grandFatherGate() external view returns(uint256);
    function brunGate() external view returns(uint256);
}
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view  returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public  onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract IDO is Ownable{
    address USDT;
    address SGRToken;
    address defaultAddr;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public price;
    
    
    function init(address _SGRtoken, address _USDT, address _defaultAddr, uint256 _price, uint256 _startTime, uint256 _endTime) public onlyOwner() {
        SGRToken = _SGRtoken;
        USDT = _USDT;
        defaultAddr = _defaultAddr;
        startTime = _startTime;
        endTime = _endTime;
        price = _price;
    }

    function buy(uint256 _amount) public {
        require(now >= startTime,"not begin!");
        require(now < endTime, "is end!");
        IERC20(USDT).transferFrom(msg.sender, defaultAddr, _amount);
        IERC20(SGRToken).transfer(msg.sender, _amount * price);
    }

    function getPrice(uint256 _amount) public view returns(uint256){
            return _amount * price;
    }
    
    function getBalance() public onlyOwner{
        uint256 _amount = IERC20(SGRToken).balanceOf(address(this));
        require(now > endTime);
        IERC20(SGRToken).transfer(defaultAddr, _amount);
    }

}