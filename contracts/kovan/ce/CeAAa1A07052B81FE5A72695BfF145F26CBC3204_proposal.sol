// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: daoproposalContract.sol


pragma solidity ^0.8.0;

pragma experimental ABIEncoderV2;



contract proposal is Ownable{

    IERC20 public depositToken;
    uint256 count1;
    uint256 count2;

    struct Proposal {
        uint256 proposalID;
        address contractor;
        uint256 contractorProposalID;
        address moderator;
        uint256 proposalStart;
        uint256 proposalEnd;
        string status; 
        string discription;
    }


    struct Rules {
        // Index to identify a committee
        uint256 committeeID; 
        // The quorum needed for each proposal is calculated by totalSupply / minQuorumDivisor
        uint256 minPercentageOfLikes;
        // Period in minutes to consider or set a proposal before the voting procedure
        uint256 minutesSetProposalPeriod; 
        // The minimum debate period in minutes that a generic proposal can have
        uint256 minMinutesDebatePeriod;
        // The inflation rate to calculate the reward of fees to voters
        uint256 feesRewardInflationRate;
        // The inflation rate to calculate the token price (for project manager proposals) 
        uint256 tokenPriceInflationRate;
        // The default minutes funding period
        uint256 defaultMinutesFundingPeriod;
    } 

    struct proposalDecision{
        uint256 upvote;
        uint256 downvote;
        uint256 __proposalId;

    }

    

   uint256[] public _proposal;
   uint256[] public _rules;

    mapping(uint256 => Proposal) public proposaldetail;
    mapping(uint256 => Rules) public rulesInfo;
    mapping(uint256 => proposalDecision) public proposalfinal;
    mapping(address => bool) public _voterInfo;


    modifier onlyHolder {
        require(IERC20(depositToken).balanceOf(msg.sender) > 0, "only token holder can craete the proposal");
        _;
    }
 constructor()  {
        
    }
   
    function init(IERC20 _tokenAddress)external onlyOwner{
        require(address(depositToken) == address(0),"token already added");
        depositToken = _tokenAddress;
    }

    function createRule(uint256 ruleNo , Rules calldata _ruleInfo)external  onlyOwner {
        require(rulesInfo[ruleNo].committeeID == 0,"rule of that rule no is already craeted");

         rulesInfo[ruleNo]=_ruleInfo;
         _rules.push(ruleNo);
    }

    function updateRule(uint256 ruleNo , Rules calldata _ruleInfo)external onlyOwner{
        require(rulesInfo[ruleNo].committeeID == 0,"first create the rule");
        
        rulesInfo[ruleNo]=_ruleInfo;
    }

    function createProposal(uint256 _proposalId , Proposal calldata _proposalDeposite)external onlyHolder {
        require(proposaldetail[_proposalId].proposalStart == 0,"proposal of that proposalId already craeted");
    
        proposaldetail[_proposalId]=_proposalDeposite;
        _proposal.push(_proposalId);

    }

    function updateProposal(uint256 _proposalId , Proposal calldata _proposalDeposite)external onlyOwner{
        require(proposaldetail[_proposalId].proposalStart != 0,"first create the proposal");
        require(proposaldetail[_proposalId].proposalStart >= block.timestamp,"proposal canot be update when proposal voting time start");
        
        proposaldetail[_proposalId]=_proposalDeposite;
    }

    function vote(uint256 _proposalId, bool _vote ) external onlyHolder {
        require(proposaldetail[_proposalId].proposalStart <= block.timestamp ,"proposal voting time not yet started");
        require(block.timestamp <= proposaldetail[_proposalId].proposalEnd ,"proposal voting time ended");
        require(!_voterInfo[msg.sender],"user already voted");
    
        
    
            if(_vote == true){
                count1 ++;
            }else{
                count2 ++ ; 
            }
            proposalfinal[_proposalId].__proposalId = _proposalId;
            proposalfinal[_proposalId].upvote = count1;
            proposalfinal[_proposalId].downvote = count2;
            _voterInfo[msg.sender]=true;
           if(block.timestamp >= proposaldetail[_proposalId].proposalEnd){
               proposaldetail[_proposalId].status = "close";
           }
    
    }


    function proposalFinalDecision(uint256 _proposalId) public view virtual returns(bool){
        require(proposaldetail[_proposalId].proposalStart < block.timestamp ,"proposal voting time not yet started");
        
        require(block.timestamp > proposaldetail[_proposalId].proposalEnd ,"proposal voting time not yet ended");

        if(proposalfinal[_proposalId].upvote > proposalfinal[_proposalId].downvote){
            return true;
        } else{
        return false;
        }
    }



}