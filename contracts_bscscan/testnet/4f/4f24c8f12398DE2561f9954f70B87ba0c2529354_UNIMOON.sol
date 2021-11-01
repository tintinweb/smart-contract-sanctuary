/**
 *Submitted for verification at BscScan.com on 2021-10-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    event TransferDetails(address indexed from, address indexed to, uint256 total_Amount, uint256 reflected_amount, uint256 total_TransferAmount, uint256 reflected_TransferAmount);
}

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/// @author Hammad Ghazi
contract UNIMOON is Ownable {
    
    address public tokenAddress; // UNIMOON Token address
    IERC20 token;
    
    uint256 public constant MAX_BNB_CONTRIBUTION = 950000000000000000000; //950 BNB
     uint256 public currentTokenReserved;
    uint256 public tokensClaimed;
    uint256 public icoTimer;
    uint256 public unimoonICOPrice = 95000000000; // 1 BNB = 95 Billion UNIMOON tokens
    
    bool public icoState = false;
    bool public claimState = false;
    
    mapping (address => uint256) public icoBuyersContribution;
    mapping (address => uint256) public icoBuyersReserves;
    
   
    event TokensPurchased(address indexed buyer, uint256 contribution);
    
    event TokensClaimed(address indexed buyer, uint256 amount);
    
      constructor(address _tokenAddress) {
          tokenAddress=_tokenAddress;
          token = IERC20(tokenAddress);
    }
    
    function setICOTimer(uint256 _unixTime) external onlyOwner{
        icoTimer = _unixTime;
    }
    
    function setUNIMOONPrice(uint256 _newPrice) external onlyOwner {
        unimoonICOPrice = _newPrice;
    }
    
     function flipClaimState() external onlyOwner{
        claimState = !claimState;
    }
    
    function flipICOState() external onlyOwner{
        icoState = !icoState;
    }
    
    function reserveTokens() external payable {
        address buyer = msg.sender;
        require(icoState,'ICO is not started yet');
        require(!claimState,'ICO is over, you can now claim your tokens');
        require(icoTimer >= block.timestamp, "ICO has ended");
        require(msg.value>0,"No BNB sent");
                require(
            MAX_BNB_CONTRIBUTION >= getContractBnbBalance(),
            "Exceeds ICO max contribution limit"
        );
        require(8000000000000000000>=icoBuyersContribution[buyer]+msg.value,"Maximum contribution amount is 8 BNB");
        require(msg.value>=100000000000000000,"Minimum contribution amount is 0.1 BNB");
        
        uint amount = msg.value * unimoonICOPrice;
        
        icoBuyersContribution[buyer] += msg.value;
        icoBuyersReserves[buyer]+=amount;
        currentTokenReserved+=amount;
        
        emit TokensPurchased(buyer, msg.value);
    }
    
        function claimTokens() external {
        require(!icoState,'ICO is not over');
        require (claimState, 'Claiming is not live yet');
        require(block.timestamp > icoTimer , "ICO timer not passed");
        address claimer = msg.sender;
        require(icoBuyersReserves[claimer] > 0, 'You do not have any UNIMOON reserves');
        uint256 amount = icoBuyersReserves[claimer];
                require(
            token.balanceOf(address(this)) >= amount,
            "Contract does not have sufficient token balance"
        );
        icoBuyersReserves[claimer]=0;
        tokensClaimed += amount;
        currentTokenReserved -= amount;
        token.transfer(claimer, amount);
        emit TokensClaimed(claimer, amount);
    }
    
        function withdrawToken() external onlyOwner {
            uint256 tokenBalance = getContractTokenBalance() - currentTokenReserved;
        require(
            tokenBalance > 0,
            "Contract does not have any UNIMOON tokens"
        );
        bool success = token.transfer(
            tokenAddress,
            tokenBalance
        );
        require(success, "Token Transfer failed.");
    }
    
       function withdrawBNB() external onlyOwner {
           require(address(this).balance>0,"Contract does not have any BNB Balance");
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    
    function getContractTokenBalance() public view returns(uint){
        return token.balanceOf(address(this));
    }
    
    function getContractBnbBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function getUserContribution(address _addr) external view returns(uint256){
        return icoBuyersContribution[_addr];
    }
    
    function getUserReservedTokens(address _addr) external view returns(uint256){
        return icoBuyersReserves[_addr];
    }
    

}