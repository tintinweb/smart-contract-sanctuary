/**
 *Submitted for verification at BscScan.com on 2021-12-05
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

/**
 * BEP20 standard interface.
 */ 
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract AnjiReferral is Ownable {

    
    struct Referrer{
        address tokenAddress;
        uint256 bnbAmount;
        uint256 rewardAmount;
    }

    struct UserReward{
        uint256 bnbAmount;
        uint256 totalReward;
        bool claimPossible;
    }

    mapping (address => uint) public  balanceOf;
    mapping(address => Referrer[]) public referrerlist;
    mapping (address => UserReward) public userReward;
    mapping (address => uint256) public tokenDebt;
    mapping (address => uint256) public tokenPercentlist;

    constructor () {
       
        
    }

    function tokenRegister(address tokenAddr, uint256 reward_percent) external onlyOwner{
        require(reward_percent >= 0, 'invalid percent');
        require(reward_percent <= 1000, 'invalid percent');

        tokenPercentlist[tokenAddr] = reward_percent;
    }

    function referralBuy(address referrer, uint256 bnbBuy, address tokenAddr) public {
        if (bnbBuy > 0) {
            if (referrerlist[referrer].length > 0) {
                bool newRow = true;
                for (uint i=0; i<referrerlist[referrer].length; i++){
                    if (referrerlist[referrer][i].tokenAddress == tokenAddr) {
                        referrerlist[referrer][i].bnbAmount = referrerlist[referrer][i].bnbAmount + bnbBuy;
                        referrerlist[referrer][i].rewardAmount = referrerlist[referrer][i].rewardAmount + tokenPercentlist[tokenAddr]*bnbBuy/1000;
                        newRow = false;
                    }
                }
                if (newRow){
                    referrerlist[referrer].push(
                        Referrer({
                            tokenAddress: tokenAddr,
                            bnbAmount: bnbBuy,
                            rewardAmount: tokenPercentlist[tokenAddr]*bnbBuy/1000      
                        })
                    );
                }
            } else {
                referrerlist[referrer].push(
                    Referrer({
                        tokenAddress: tokenAddr,
                        bnbAmount: bnbBuy,
                        rewardAmount: tokenPercentlist[tokenAddr]*bnbBuy/1000
                    })
                );
            }
            userReward[referrer].bnbAmount = userReward[referrer].bnbAmount + bnbBuy;
            userReward[referrer].claimPossible = true;
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

    //displays reward amount of BNB for the token of the referrer
    function debtPerReferrerAndToken(address referrer, address tokenAddr) public view returns(uint256) {
        if (referrerlist[referrer].length > 0) {
            uint256 rewardAmount = 0;
            for (uint i=0; i<referrerlist[referrer].length; i++){
                if (referrerlist[referrer][i].tokenAddress == tokenAddr) {
                    rewardAmount = referrerlist[referrer][i].rewardAmount;
                }
            }
            return rewardAmount;
        } else {
            return 0;
        }
    }

    //displays purchased amount of BNB for the token of the referrer
    function BNBPerReferrerAndToken(address referrer, address tokenAddr) public view returns(uint256) {
        if (referrerlist[referrer].length > 0) {
            uint256 bnbAmount = 0;
            for (uint i=0; i<referrerlist[referrer].length; i++){
                if (referrerlist[referrer][i].tokenAddress == tokenAddr) {
                    bnbAmount = referrerlist[referrer][i].bnbAmount;
                }
            }
            return bnbAmount;
        } else {
            return 0;
        }
    }
    
    //referrer claim his reward
    function claimReward(address receiver) public{
        uint256 BNBBalance = address(this).balance;
        require(BNBBalance > 0, 'insufficient balance');
        require(userReward[receiver].totalReward > 0, 'no reward');
        require(userReward[receiver].claimPossible, 'already claimed');

        if (referrerlist[receiver].length > 0) {
            for (uint i=0; i<referrerlist[receiver].length; i++){
                tokenDebt[referrerlist[receiver][i].tokenAddress] = tokenDebt[referrerlist[receiver][i].tokenAddress] - referrerlist[receiver][i].rewardAmount; 
                referrerlist[receiver][i].rewardAmount = 0;            
            }
        }

        payable(receiver).transfer(userReward[receiver].totalReward);
        userReward[receiver].totalReward = 0;
        userReward[receiver].claimPossible == false;
    }

    /**
     * @notice deposit WBNB from external
     *
     */
    function depositExternalBNB() external payable {
        balanceOf[address(this)] += msg.value;
    }

    //Allow owner to withdraw BNB for emergency
    function withdrawBNB(address receiver) external onlyOwner {
        uint256 BNBBalance = address(this).balance;
        require(BNBBalance > 0, 'insufficient balance');
        payable(receiver).transfer(BNBBalance);
    }

    receive() external payable { }
}