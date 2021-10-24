// 0.5.1-c8a2
// Enable optimization
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract Control {
    
    using SafeMath for uint256;
    IERC20 public mt;
    address public owner;
    uint256 minBnbValue = 1000000000000000;
    uint256 maxBnbValue = 5000000000000000000;
    uint256 public ktnum = 0;
    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _rewardTokenbalances;
    mapping (address => uint256) private _rewardBnbbalances;
    mapping (address => address) private _userShip;
    
    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () public payable {
        owner = msg.sender;
        mt = IERC20(0xd40b8de58139136563bFDE9f3FEE9799A8bFC5Cd);
        // mt.balanceOf{value:1}(owner);
    }
    
    modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
	
	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		owner = newOwner;
	}
    
    function balanceOf(address account) public view returns (uint256) {
        return mt.balanceOf(account);
    }
    
    function balanceKtOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    function getMeBnb() public view returns (uint256) {
        return address(this).balance;
    }
    
    function getRewardToken(address account) public view returns (uint256) {
        return _rewardTokenbalances[account];
    }
    
    function getUserShip(address account) public view returns (address) {
        return _userShip[account];
    }
    
    function getNowTime() public view returns (uint256) {
        return block.timestamp;
    }
    
    
    function getUserData(address account) public view returns (address,uint256,uint256,uint256,uint256,uint256) {
        uint256 bnbNum = account.balance;
        return (_userShip[account],bnbNum,_balances[account],_rewardTokenbalances[account],balanceOf(account),_rewardBnbbalances[account]);
    }
    function withDrawKt() public  returns (uint256) {
        address account = msg.sender;
        require(ktnum <= 1000, "ERC20: amount over");
        require( _balances[account] == 0, "ERC20: have withDraw");
        _balances[account] = 50000000000000000000;
        mt.transfer(account,50000000000000000000);
        ktnum = ktnum.add(1);
        return 50000000000000000000;
    }
    function userShip(address parent) public returns (bool){
		require(parent != address(0), "Control: userShip is not zero");
		require(_userShip[msg.sender]== address(0), "Control: parent is have");
		_userShip[msg.sender] = parent;
		return true;
	}
    function swap() payable public returns (bool){
        uint256 bnbAmount = msg.value;
        require(bnbAmount > minBnbValue, "ERC20: bnbAmount too small");
        require(bnbAmount < maxBnbValue, "ERC20: bnbAmount too big");
        mt.transfer(msg.sender,bnbAmount.mul(6000));
        rewardParent(msg.sender,bnbAmount);
        return true;
    }
    function rewardParent(address account,uint256 bnbAmount) internal{
        address parent =  _userShip[account];
        if(parent!=address(0)){
            _rewardTokenbalances[parent] = _rewardTokenbalances[parent].add(bnbAmount.mul(6000).mul(12).div(100));
            // payable(parent).transfer(bnbAmount.mul(12).div(100));
            _rewardBnbbalances[parent] = _rewardBnbbalances[parent].add(bnbAmount.mul(12).div(100));
            address gparent =  _userShip[parent];
            if(gparent!=address(0)){
                 _rewardTokenbalances[gparent] = _rewardTokenbalances[gparent].add(bnbAmount.mul(6000).mul(6).div(100));
                //  payable(gparent).transfer(bnbAmount.mul(6).div(100));
                 _rewardBnbbalances[gparent] = _rewardBnbbalances[gparent].add(bnbAmount.mul(6).div(100));
            }
        }
    }
    
    function withDraw() payable onlyOwner public returns (bool){
        payable(msg.sender).transfer(getMeBnb());
        return true;
    }
    
    function withDraw(uint256 bnbAmount) payable onlyOwner public returns (bool){
        payable(msg.sender).transfer(bnbAmount);
        return true;
    }
    
    function withDrawToken(uint256 tokenAmount) public onlyOwner returns (bool){
        mt.transfer(msg.sender,tokenAmount);
        return true;
    }
    function userWithDrawBnb() payable public returns (bool){
        payable(msg.sender).transfer(_rewardBnbbalances[msg.sender]);
        _rewardBnbbalances[msg.sender] = 0;
        return true;
    }
    function userWithDrawRewardToken() payable public returns (bool){
        mt.transfer(msg.sender,_rewardTokenbalances[msg.sender]);
        _rewardTokenbalances[msg.sender] = 0;
        return true;
    }
    
    receive() external payable {}
}