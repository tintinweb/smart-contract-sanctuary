/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IBEP20 {
    
    function totalSupply() external view returns (uint256);
   
    function balanceOf(address account) external view returns (uint256);
   
    function transfer(address recipient, uint256 amount) external returns (bool);
   
    function allowance(address owner, address spender) external view returns (uint256);
 
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool); 
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
pragma solidity ^0.8.0;
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
// 1 MTOKEN = 0.10 during presale 

contract publicCrowdsale is Context, Ownable{
    IBEP20 public token;
    uint256 public startTime;
    uint256 public endTime;
    address payable public wallet;
    uint256 public rate; //0.10 cents per token during presale How many tokens do i get from 1 WEI 
    //1 MTOKEN = 500000000000000 WEI
    uint256 public weiBNBraised;


    event tokenAcquisition (address indexed buyer, address indexed receiver, uint256 value, uint256 amount);
    constructor (uint256 _rate, address payable _wallet, IBEP20 _token) public{
        //require(_startTime >= block.timestamp);
        //require(_endTime >= _startTime);
        require(_rate > 0);
        require(_wallet != address(0));

        //startTime = _startTime;
        //endTime = _endTime;
        rate = _rate;
        wallet = _wallet;
        token = _token;
    }

    receive() external payable{
        buyTokens(msg.sender);
    }
    function remainingTokens() public view returns(uint256){
        return token.balanceOf(address(this));
    }
    function transferUnsold()public onlyOwner{
        uint256 currentBalance = token.balanceOf(address(this));
        token.transfer(owner(), currentBalance);
    }

     function buyTokens(address beneficiary) public payable {
         require(token.balanceOf(address(this))>0,"Sold out");
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = weiAmount*getRate();

        // update state
        weiBNBraised = weiBNBraised+weiAmount;

        token.transfer(beneficiary, tokens);
        emit tokenAcquisition(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

    function forwardFunds() internal { //after sucessfully receiving the funds transfer them to sender
        wallet.transfer(msg.value);
    }
    function validPurchase() internal view returns (bool) {
        //bool withinPeriod = block.timestamp >= startTime && block.timestamp <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return  nonZeroPurchase;
    }
     function hasEnded() public view returns (bool) {
        return block.timestamp > endTime;
    }
    function getRate() public view returns (uint256) {
        return rate;
    }
}