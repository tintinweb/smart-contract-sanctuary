/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

/**
 * BNB Distributor
 */

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

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

interface ANJI {
    function depositExternalBNB() external payable;
}

contract BNBDistributor is Ownable {
    using SafeMath for uint256;

    //address public WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    //address public WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; //BSC testnet WBNB address
    
    mapping (address => uint) public  balanceOf;
    
    address public marketingWallet;
    address public charityWallet;
    address public anjiTokenContract;
    uint256 public marketingFee = 33;
    uint256 public charityFee = 34;
    uint256 public anjiFee = 33;
    
    bool public marketingTransferEnabled = true; 
    
    constructor () {
        
    }
    
     /**
     * @notice set the Anji token address by owner
     *
     * @param _anjiTokenContract: Anji token address
     */
    function setAnjiTokenAddress(address _anjiTokenContract) external onlyOwner {
        anjiTokenContract = _anjiTokenContract;
    }
    
    /**
     * @notice set the marketing wallet address by owner
     *
     * @param _marketingWallet: market wallet address
     */
    function setMarketingWalletAddress(address _marketingWallet) external onlyOwner {
        marketingWallet = _marketingWallet;
    }
    
    /**
     * @notice set the charity wallet address by owner
     *
     * @param _charityWallet: charity wallet address
     */
    function setCharityWalletAddress(address _charityWallet) external onlyOwner {
        charityWallet = _charityWallet;
    }
    
    /**
     * @notice set the marketing wallet fee by owner
     *
     * @param _marketingFee: fee(%) for marketing 
     */
    function setMarketingFee(uint256 _marketingFee) external onlyOwner {
        marketingFee = _marketingFee;
    }
    
    /**
     * @notice set the charity wallet fee by owner
     *
     * @param _charityFee: fee(%) for charity
     */
    function setCharityFee(uint256 _charityFee) external onlyOwner {
        charityFee = _charityFee;
    }
    
    /**
     * @notice set the Anji token fee by owner
     *
     * @param _anjiFee: fee(%) for Anji token contract
     */
    function setAnjiFee(uint256 _anjiFee) external onlyOwner {
        anjiFee = _anjiFee;
    }
    
    /**
     * @notice turn on or off the marketing transfer by owner
     *
     * @param _marketingTransferEnabled: fee(%) for Anji token contract
     */
    function enableMarketingTransfer(bool _marketingTransferEnabled) external onlyOwner {
        marketingTransferEnabled = _marketingTransferEnabled;
    }
    
    /**
     * @notice distribute the dividend
     *
     */
    function distributeDividend() public{
        //uint256 amount = IBEP20(WBNB).balanceOf(address(this));
        //ANJI(anjiTokenContract).depositExternalBNB();
        
        uint256 amount = address(this).balance;
        require(amount > 0, "Balance is insufficient.");
        
        uint256 amountToMarketing = amount.mul(marketingFee).div(100);
        uint256 amountToCharity = amount.mul(charityFee).div(100);
        uint256 amountToAnji = amount.mul(anjiFee).div(100);
        
        uint256 distributedTotalAmount = amountToMarketing + amountToCharity + amountToAnji;
        require(amount >= distributedTotalAmount, "The amount distributed exceeds the total amount.");
        
        if (!marketingTransferEnabled){
            amountToMarketing = 0;
            //amountToAnji = amount.mul(uint256(100).sub(charityFee)).div(100);
			amountToAnji = amountToAnji.add(amountToMarketing);
        } 
        
        if (amountToMarketing >0) { payable(marketingWallet).transfer(amountToMarketing); }
        if (amountToCharity >0) { payable(charityWallet).transfer(amountToCharity); }
        if (amountToAnji >0) { 
            payable(anjiTokenContract).transfer(amountToAnji); 
            ANJI(anjiTokenContract).depositExternalBNB{value: amountToAnji}();
        }
    }
    
    /**
     * @notice distribute the dividend
     *
     */
    function distributeDividend1() public{
        //uint256 amount = IBEP20(WBNB).balanceOf(address(this));
        //ANJI(anjiTokenContract).depositExternalBNB();
        
        uint256 amount = address(this).balance;
        require(amount > 0, "Balance is insufficient.");
        
        uint256 amountToMarketing = amount.mul(marketingFee).div(100);
        uint256 amountToCharity = amount.mul(charityFee).div(100);
        uint256 amountToAnji = amount.mul(anjiFee).div(100);
        
        uint256 distributedTotalAmount = amountToMarketing + amountToCharity + amountToAnji;
        require(amount >= distributedTotalAmount, "The amount distributed exceeds the total amount.");
        
        if (!marketingTransferEnabled){
            amountToMarketing = 0;
            //amountToAnji = amount.mul(uint256(100).sub(charityFee)).div(100);
			amountToAnji = amountToAnji.add(amountToMarketing);
        } 
        
        if (amountToMarketing >0) { payable(marketingWallet).transfer(amountToMarketing); }
        if (amountToCharity >0) { payable(charityWallet).transfer(amountToCharity); }
        if (amountToAnji >0) { 
            payable(anjiTokenContract).transfer(amountToAnji); 
            ANJI(payable(anjiTokenContract)).depositExternalBNB();
        }
    }
    
    /**
     * @notice distribute the dividend
     *
     */
    function distributeDividend2() public{
        //uint256 amount = IBEP20(WBNB).balanceOf(address(this));
        //ANJI(anjiTokenContract).depositExternalBNB();
        
        uint256 amount = address(this).balance;
        require(amount > 0, "Balance is insufficient.");
        
        uint256 amountToMarketing = amount.mul(marketingFee).div(100);
        uint256 amountToCharity = amount.mul(charityFee).div(100);
        uint256 amountToAnji = amount.mul(anjiFee).div(100);
        
        uint256 distributedTotalAmount = amountToMarketing + amountToCharity + amountToAnji;
        require(amount >= distributedTotalAmount, "The amount distributed exceeds the total amount.");
        
        if (!marketingTransferEnabled){
            amountToMarketing = 0;
            //amountToAnji = amount.mul(uint256(100).sub(charityFee)).div(100);
			amountToAnji = amountToAnji.add(amountToMarketing);
        } 
        
        if (amountToMarketing >0) { payable(marketingWallet).transfer(amountToMarketing); }
        if (amountToCharity >0) { payable(charityWallet).transfer(amountToCharity); }
        if (amountToAnji >0) { 
            payable(anjiTokenContract).transfer(amountToAnji); 
            ANJI(payable(anjiTokenContract)).depositExternalBNB{ value: amountToAnji }();
        }
    }
    
    
    /**
     * @notice return BNB balance of  this contract
     *
     */
    function BNBbalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @notice deposit WBNB from external
     *
     */
    function depositExternalBNB() external payable {
        balanceOf[address(this)] += msg.value;
    }
    
    /**
     * @notice withdraw WBNB from this contract to the "receiver" address
     *
     */
    function withdrawBNB(address receiver) external onlyOwner {
        uint256 BNBBalance = address(this).balance;
        require(BNBBalance > 0, 'Balance is insufficient');
        if (BNBBalance > 0) {
            payable(receiver).transfer(BNBBalance);
        }
    }
    
     /**
     * @notice withdraw any other tokens that are NOT ANJI tokens
     *
     * @param tokenaddress: token address that withdraw
     * @param receiver: receiver address
     */
    function withdrawTokens(address tokenaddress, address receiver) external onlyOwner {
        require(tokenaddress != address(this), 'can not withdraw Anji token');
        uint256 tokenBalance = IBEP20(tokenaddress).balanceOf(address(this));
        if (tokenBalance > 0) {
            IBEP20(tokenaddress).transfer(receiver, tokenBalance);
        }
    }
    
}