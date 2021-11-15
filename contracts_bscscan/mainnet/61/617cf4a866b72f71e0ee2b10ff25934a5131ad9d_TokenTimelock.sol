// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./SafeMath.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 */
contract TokenTimelock {
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ERC20 basic token contract being held
    IERC20 private immutable _token;
    
    // ERC20 basic token contract being held
    IERC20 private immutable _busd;

    mapping(address => uint256) private userGrant;
    
    //Release time periods
    uint256 public _startTime;
    
    address private owner;
    
     //Number of Total Grants
    uint256 public nGrants;
    
     //Total Claimed
    uint256 public totalClaimed;
    
    //Release time periods
    uint256[] private _releaseTime;
    
     //Release percentages
    uint256[] private _releaseBlock;
    
    address private multisig;
    
    uint256 private bought;
    
    uint256 internal UNIT = 10**18;
    
    uint256 private sold_out = 100000 * UNIT;
    
    mapping(address => uint256) private userClaimed;
    
    modifier onlyOwner(){
        require(owner == msg.sender, "Only owner allowed to call this function");
        _;
    }
    

    constructor(address sig, 
        IERC20 token_, IERC20 busd_token, uint256 startTime, uint256 cliffTime, uint256 cliffPercentage, uint256 vestPeriod, uint256 numberVests, uint256 vestPercentage
    ) {
        require(startTime >= block.timestamp, "Invalid start time, you can only start time with values from the future");
        //owner
        owner = msg.sender;
        //fuse token
        _token = token_;
        
        multisig = sig;
        
        _busd = busd_token;
        
        _startTime = startTime;
        
        uint256 firstRelease = startTime.add(cliffTime);
        
        _releaseTime.push(firstRelease);
        _releaseBlock.push(cliffPercentage);
        
        require(cliffPercentage.add(numberVests.mul(vestPercentage)) == 100, "Percentage is not equal to 100");
        bought = 0;
        
        
        uint256 n; 
        while( n < numberVests){
            firstRelease = firstRelease.add(vestPeriod);
            _releaseTime.push(firstRelease);
            _releaseBlock.push(vestPercentage);
            n++;
        }
    }

    /**
     * @return the token being held.
     */
    function token() public view virtual returns (IERC20) {
        return _token;
    }
    
     /**
     * @return the multisig
     */
    function getMultisig() public view virtual returns (address) {
        return multisig;
    }
    
     /**
     * @return the token being paid
     */
    function busd() public view virtual returns (IERC20) {
        return _busd;
    }
    
    function getRate() public view virtual returns (uint256) {
        return 500;
    }
    
    function getBought() public view virtual returns (uint256) {
        return bought;
    }


    function addBeneficiary(address addr, uint256 amount) internal  {
        require(addr != address(0), "Address Invalid");
        nGrants++;
        userGrant[addr] = userGrant[addr].add(amount);
    }

    function getBeneficiaryTotalAmount(address addr) public view returns (uint256){
        require(addr != address(0), "Invalid index");
        return userGrant[addr];
    }
    
    
    function getUserAmountClaimed(address addr) public view returns (uint256){
        require(addr != address(0), "Invalid address");
        return userClaimed[addr];
    }
    
     function releaseTime(uint256 idx) public view returns (uint256){
        return _releaseTime[idx];
    }
    
    
    function releasePercentage(uint256 idx) public view returns (uint256){
        return _releaseBlock[idx];
    }
    
   
    function availableAmount(address user) public view  returns(uint256){
        uint256 am = getBeneficiaryTotalAmount(user);

        uint256 n = 0; 
        uint256 avAmount = 0;
        while (n < _releaseTime.length) {
            if(_releaseTime[n] <= block.timestamp){
                avAmount = avAmount.add(_releaseBlock[n]);
            }
            n++;
        }
       return  avAmount.mul(am).div(100);
       
    }
    
    function buy(uint256 amount) public{
        
        //value with decimals
        uint256 value = amount * UNIT;
        
        //sold tokens not bigger than 100k
        require( bought < sold_out , "sold out");
        
        //max amount is 100k 
        uint256 a = (bought.add(value) > sold_out ) ? sold_out.sub(bought) : value;
        
        a = (userGrant[msg.sender].add(a) > 25000 * UNIT ) ? (25000 * UNIT).sub(userGrant[msg.sender]) : a ;
        
        require(a > 0, "Amount invalid");
        
        //Transfer to contract
        busd().safeTransferFrom(msg.sender, address(this), a);
        
        //Add bought amount
        bought.add(value);
        
        //Correspond tokens amount
        uint256 Fuse_tokens = getRate().mul(a).div(10**10);
        
        //addBeneficiary
        addBeneficiary(msg.sender, Fuse_tokens);
       
       //contract to multisig
        busd().safeTransfer(multisig, a);
    }
    
    function withdraw_BUSD(uint256 amount) public onlyOwner{
        busd().safeTransfer(multisig, amount);
    }
    
     function withdraw_any_token(address tok, uint256 amount) public onlyOwner{
        IERC20(tok).safeTransfer(multisig, amount);
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public virtual {
        require(block.timestamp >= _releaseTime[0], "TokenTimelock: current time is before first release time");

        uint256 amount = availableAmount(msg.sender).sub(getUserAmountClaimed(msg.sender));
        require(amount > 0, "TokenTimelock: no tokens to release");

        userClaimed[msg.sender] = userClaimed[msg.sender].add(amount);
        
        totalClaimed = totalClaimed.add(amount);
    
        token().safeTransfer(msg.sender, amount);
    }
}