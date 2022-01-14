/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: contracts/governance.sol


pragma solidity 0.8.7;

  /****************************************|
  |     Interfaces And Imports             |
  |_______________________________________*/



interface IGovernance {
    function getGovernance(address user) external view returns (bool);
}


contract Voting is Ownable {

   /****************************************|
  |          Local Variables                |
  |_______________________________________*/

    // This is a type for a single proposal.
    struct Proposal {
        string name;   
        string URI;   
        uint voteCount; 
        bool published;
        uint originatedBlock;
        uint blockTime;
        address sender;
        address publisher;
        mapping(address => bool) voted;
    }

    address public variableToken=address(0) ;   
    address private governanceContractAddress;

    uint private winningBar;
    mapping (uint => Proposal) proposals;
    uint private numProposals=0;
    uint private ProposePrice;

   /****************************************|
  |                Constructor              |
  |_______________________________________*/


    constructor() {
    }


   /****************************************|
  |          Mutable Functions              |
  |_______________________________________*/


    function claimVariable(uint proposal) public{
    require(((proposals[proposal].sender==msg.sender)||(proposals[proposal].publisher==msg.sender)),"Only A Sender Or A Publisher Can Claim Their Tokens");
       if(proposals[proposal].sender==msg.sender){
     if(proposals[proposal].voteCount>winningBar){
        IERC20(variableToken).transfer(msg.sender,ProposePrice);
        proposals[proposal].sender=address(0);
     }
       }
         if(proposals[proposal].publisher==msg.sender){
          if(proposals[proposal].voteCount>winningBar){
        IERC20(variableToken).transfer(msg.sender,ProposePrice);
            proposals[proposal].publisher=address(0);
          }
       }
    }

    
    function setVariableToken(address token) public onlyOwner{
    variableToken=token;
    }

   function setVotingPrice(uint256 price) public onlyOwner{
    ProposePrice=price;
    }

    function setGovernanceAddress(address _address) public onlyOwner{
        governanceContractAddress=_address;
    }

     function setWinningBar(uint _bar) public onlyOwner{
        winningBar=_bar;
    }

    function vote(uint proposal) external {
        require(proposals[proposal].voted[msg.sender]==false,"User Already Voted For This Proposal");
        require(proposals[proposal].published==true,"Proposal Is Not Published");
        require(block.number<(proposals[proposal].originatedBlock+proposals[proposal].blockTime),"Proposal Time Limit Has Passed");
        IGovernance governanceContract=IGovernance(governanceContractAddress);
        require(governanceContract.getGovernance(msg.sender),"User Has No Governance To Vote");
        proposals[proposal].voted[msg.sender]=true;
        proposals[proposal].voteCount =  proposals[proposal].voteCount+1;
    }


    function propose(string memory _name,string memory _uri,uint _blockTime) public {
        IGovernance governanceContract=IGovernance(governanceContractAddress);
        require(governanceContract.getGovernance(msg.sender),"User Has No Governance To Propose");
         require( IERC20(variableToken).balanceOf(msg.sender)>(ProposePrice),"Not Enough Variable Token To Propose");
        IERC20(variableToken).transferFrom(msg.sender,address(this),ProposePrice);
        Proposal storage p = proposals[numProposals++];
                p.name = _name;
                p.URI = _uri;
                p.voteCount = 0;
                p.published = false;
                p.originatedBlock = block.number;
                p.blockTime = _blockTime;
                p.sender = msg.sender;
    }

  function publishProposal(uint proposal) public {
      require(proposals[proposal].published==false,"Proposal Is Already Published");
      require(proposals[proposal].sender!=msg.sender,"A Sender Can't Publish His Own Proposal");
        IGovernance governanceContract=IGovernance(governanceContractAddress);
      require(governanceContract.getGovernance(msg.sender),"User Has No Governance To Publish A Vote");
        require( IERC20(variableToken).balanceOf(msg.sender)>ProposePrice,"Not Enough Variable Token To Publish");
        IERC20(variableToken).transferFrom(msg.sender,address(this),(ProposePrice));
        proposals[proposal].published=true;
        proposals[proposal].publisher=msg.sender;
        proposals[proposal].originatedBlock=block.number;
    }

  /****************************************|
  |       Non Mutable Functions            |
  |_______________________________________*/
 
    function isWinner(uint proposal) external view returns (bool winner)
    {
         winner=false;
        if(proposals[proposal].voteCount>winningBar){
            winner=true;
        }
    }
        function getProposePrice() external view returns (uint256 _price)
    {
        _price = ProposePrice;
    }

     function getName(uint proposal) external view returns (string memory _name)
    {
        _name =  proposals[proposal].name;
    }
      function getURI(uint proposal) external view returns (string memory _uri)
    {
        _uri =  proposals[proposal].URI;
    }
          function getVoteCount(uint proposal) external view returns (uint256 _voteCount)
    {
        _voteCount =  proposals[proposal].voteCount;
    }
          function getPublished(uint proposal) external view returns (bool _published)
    {
        _published =  proposals[proposal].published;
    }
         function getOriginatedBlock(uint proposal) external view returns (uint256 _block)
    {
        _block =  proposals[proposal].originatedBlock;
    }
        function getBlockTime(uint proposal) external view returns (uint256 _blocks)
    {
        _blocks =  proposals[proposal].blockTime;
    }
           function getSender(uint proposal) external view returns (address _sender)
    {
        _sender =  proposals[proposal].sender;
    }
         function getVoted(uint proposal,address _address) external view returns (bool _voted)
    {
        _voted =  proposals[proposal].voted[_address];
    }
      function getPublisher(uint proposal) external view returns (address _publisher)
    {
        _publisher =  proposals[proposal].publisher;
    }
        function getVariableToken() public view returns (address){
        return variableToken;
        }
    function adminWithdraw(address token) public onlyOwner{
    IERC20(token).transfer(msg.sender,IERC20(token).balanceOf(address(this)));
  }

   function adminWithdrawETH(address payable admin) public onlyOwner{
    admin.transfer(address(this).balance);
  }

}