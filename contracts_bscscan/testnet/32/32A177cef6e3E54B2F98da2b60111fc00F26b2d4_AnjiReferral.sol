/**
 *Submitted for verification at BscScan.com on 2021-12-13
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
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

contract AnjiReferral is Ownable {
    
    struct Referrer{
        uint256 bnbAmount;
        uint256 rewardAmount;
    }

    struct UserReward{
        uint256 bnbAmount;
        uint256 totalReward;
    }

    mapping (address => uint) public  balanceOf;
    mapping (address => uint256) public  bnbDeposits;
    //mapping(address => Referrer[]) public referrerlist;
    mapping(address => mapping(address => Referrer)) public referrerlist;
    mapping (address => UserReward) public userReward;
    mapping (address => uint256) public tokenDebt;
    mapping (address => uint256) public tokenPercentlist;

    address public anjiRouter;

    constructor () {       
        
    }

    /**
     * @notice set the AnjiRouter contract address by owner
     *
     * @param _anjiRouter: AnjiRouter contract address
     */
    function setAnjiRouter(address _anjiRouter) external onlyOwner {
        anjiRouter = _anjiRouter;
    }


    function tokenRegister(address tokenAddr, uint256 reward_percent) external onlyOwner{
        require(reward_percent >= 0, 'invalid percent');
        require(reward_percent <= 1000, 'invalid percent');

        tokenPercentlist[tokenAddr] = reward_percent;
    }

    function referralBuy(address referrer, uint256 bnbBuy, address tokenAddr) external {
		require(msg.sender==anjiRouter, 'AnjiRouter can only call');
        if (tokenPercentlist[tokenAddr] > 0 && bnbBuy > 0) {            
            referrerlist[referrer][tokenAddr].bnbAmount = referrerlist[referrer][tokenAddr].bnbAmount + bnbBuy;
            referrerlist[referrer][tokenAddr].rewardAmount = referrerlist[referrer][tokenAddr].rewardAmount + tokenPercentlist[tokenAddr]*bnbBuy/1000;
            userReward[referrer].bnbAmount = userReward[referrer].bnbAmount + bnbBuy;
            userReward[referrer].totalReward = userReward[referrer].totalReward + tokenPercentlist[tokenAddr]*bnbBuy/1000;
            tokenDebt[tokenAddr] = tokenDebt[tokenAddr] + tokenPercentlist[tokenAddr]*bnbBuy/1000;
        }
    }   
    
    //displays total amount of BNB is owed to each referrer for the token(not paid)
    function debtPerToken(address tokenAddr) public view returns(uint256) {
        return tokenDebt[tokenAddr];
    }

    //displays total reward amount of BNB for the referrer
    function debtPerReferrer(address referrer) public view returns(uint256) {
        return userReward[referrer].totalReward;
    }

    //displays total purchased amount of BNB for the referrer
    function BNBPerReferrer(address referrer) public view returns(uint256) {
        return userReward[referrer].bnbAmount;
    }

    //displays reward amount of BNB for the token of the referrer
    function debtPerReferrerAndToken(address referrer, address tokenAddr) public view returns(uint256) {
        return referrerlist[referrer][tokenAddr].rewardAmount;
    }

    //displays purchased amount of BNB for the token of the referrer
    function BNBPerReferrerAndToken(address referrer, address tokenAddr) public view returns(uint256) {
        return referrerlist[referrer][tokenAddr].bnbAmount;
    }

    //displays total amount of BNB within the contract (not yet claimed)
    function depositedPerToken(address tokenAddr) public view returns(uint256) {
        return bnbDeposits[tokenAddr];
    }

    // displays total amount of BNB needed to be deposited
    function perTokenDepositRequired(address tokenAddr) public view returns(uint256) {
        if (tokenDebt[tokenAddr] >= bnbDeposits[tokenAddr]) {
            return tokenDebt[tokenAddr] - bnbDeposits[tokenAddr];
        }
        return 0;
    }

    //referrer claim his reward
    function claimReward(address receiver, address tokenAddr) public{
        uint256 BNBBalance = address(this).balance;
        require(BNBBalance > 0, 'insufficient balance');
        require(referrerlist[receiver][tokenAddr].rewardAmount > 0, 'insufficient balance per the token');

        require(bnbDeposits[tokenAddr] >= referrerlist[receiver][tokenAddr].rewardAmount, 'insufficient token balance');

        tokenDebt[tokenAddr] = tokenDebt[tokenAddr]  - referrerlist[receiver][tokenAddr].rewardAmount; 
        bnbDeposits[tokenAddr] = bnbDeposits[tokenAddr] - referrerlist[receiver][tokenAddr].rewardAmount;

        payable(receiver).transfer(referrerlist[receiver][tokenAddr].rewardAmount);
        userReward[receiver].totalReward = userReward[receiver].totalReward - referrerlist[receiver][tokenAddr].rewardAmount;

        referrerlist[receiver][tokenAddr].rewardAmount = 0;   
        
    }

    /**
     * @notice deposit WBNB from external
     *
     */
    function depositExternalBNB(address tokenAddr) external payable {
        balanceOf[address(this)] += msg.value;
        bnbDeposits[tokenAddr] += msg.value;
    }
    //Allow owner to withdraw BNB for emergency
    function withdrawBNB(address receiver) external onlyOwner {
        uint256 BNBBalance = address(this).balance;
        require(BNBBalance > 0, 'insufficient balance');
        payable(receiver).transfer(BNBBalance);
    }


    receive() external payable { }
}