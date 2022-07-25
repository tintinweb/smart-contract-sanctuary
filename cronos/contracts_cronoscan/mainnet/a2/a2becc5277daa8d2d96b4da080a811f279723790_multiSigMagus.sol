/**
 *Submitted for verification at cronoscan.com on 2022-05-25
*/

//Multisig wallet by https://github.com/stqc

pragma solidity >=0.8.0;

interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


contract multiSigMagus{

    mapping(address=>bool) public isAuthorized;
   
    struct proposals{
            uint256 voteInFavour;
            address receiver;
            address token;
            uint256 voteAgainst;
            string reason;
            address issuer;
            mapping(address=>bool) hasVoted;
            uint256 amount;
            bool isCompleted;
    } 

    mapping(uint256=>proposals) public allProposals;

    uint256 public currentPropsal =0;
    address public owner;
    
    constructor(){

            owner=msg.sender;
    }

    function authorizeWallet(address wallet) external{
        require(msg.sender==owner,"Only Owner can authorize");
        isAuthorized[wallet]=true;
    }

    function revokeWallet(address wallet) external{
        require(msg.sender==owner,"ONly owner can revoke");
        isAuthorized[wallet]=false;
    }

    function issueProposal(address rec,address asset, string memory reason, uint256 amount) external{
            require(isAuthorized[msg.sender],"Only authorized wallets can issue a proposal");
                       

            allProposals[currentPropsal].receiver = rec;
            allProposals[currentPropsal].token = asset;
            allProposals[currentPropsal].reason = reason;
            allProposals[currentPropsal].voteInFavour+=1;
            allProposals[currentPropsal].voteAgainst=0;
            allProposals[currentPropsal].hasVoted[msg.sender]=true;
            allProposals[currentPropsal].issuer=msg.sender;
            allProposals[currentPropsal].amount=amount;
            allProposals[currentPropsal].isCompleted=false;

    }

    function voteInFavour() external{
        require(isAuthorized[msg.sender],"Only authorized can vote");
        require(!allProposals[currentPropsal].hasVoted[msg.sender],"You have already voted");
        require(!allProposals[currentPropsal].isCompleted,"no transaction left to confirm");
        require(allProposals[currentPropsal].token!=address(0),"The transaction hass not been set up yet");
        allProposals[currentPropsal].voteInFavour+=1;
        allProposals[currentPropsal].hasVoted[msg.sender]=true;
        if(allProposals[currentPropsal].voteInFavour>2){
                
                IBEP20 token = IBEP20(allProposals[currentPropsal].token);
                token.approve(address(this),allProposals[currentPropsal].amount);
                token.transferFrom(address(this),allProposals[currentPropsal].receiver,allProposals[currentPropsal].amount);
                allProposals[currentPropsal].isCompleted=true;
                            currentPropsal+=1;
        }

    }

    function voteAgainst() external{
        require(isAuthorized[msg.sender],"Only authorized can vote");
        require(!allProposals[currentPropsal].hasVoted[msg.sender],"You have already voted");
        require(!allProposals[currentPropsal].isCompleted,"no transaction left to confirm");
        require(allProposals[currentPropsal].token!=address(0),"The transaction hass not been set up yet");
        allProposals[currentPropsal].voteAgainst+=1;
        allProposals[currentPropsal].hasVoted[msg.sender]=true;
        if(allProposals[currentPropsal].voteAgainst>2){

                allProposals[currentPropsal].isCompleted=true;
                            currentPropsal+=1;
        }

    }



}