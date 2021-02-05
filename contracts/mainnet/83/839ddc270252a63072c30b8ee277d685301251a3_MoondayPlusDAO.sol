/**
 *Submitted for verification at Etherscan.io on 2021-02-05
*/

pragma solidity ^0.6.2;




/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// 
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    
    
    
    function calculateBurnFee(uint256 _amount) external view returns (uint256);
    
    
    function mint(address account, uint256 amount) external;
    
    
    function burn(address account, uint256 amount) external;

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



interface Uniswapv2Pair {

     function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
 

}


/**
 * @title MoonDayPlus DAO
 * @dev Made by SoliditySam and Grass, fuck bad mouths saying I didnt made OG tendies
 *
 * 
          ,
       _/ \_     *
      <     >
*      /.'.\                    *
             *    ,-----.,_           ,
               .'`         '.       _/ \_
    ,         /              `\    <     >
  _/ \_      |  ,.---.         \    /.'.\
 <     >     \.'    _,'.---.    ;   `   `
  /.'.\           .'  (-(0)-)   ;
  `   `          /     '---'    |  *
                /    )          |             *
     *         |  .-;           ;        ,
               \_/ |___,'      ;       _/ \_ 
          ,  |`---.MOON|_       /     <     >
 *      _/ \_ \         `     /        /.'.\
       <     > '.          _,'         `   `
 MD+    /.'.\    `'------'`     *   
        `   `
 
 
 */

// The DAO contract itself
contract MoondayPlusDAO {
    
        using SafeMath for uint256;

    // The minimum debate period that a generic proposal can have
       uint256 public minProposalDebatePeriod = 2 weeks;
      
       
       // Period after which a proposal is closed
       // (used in the case `executeProposal` fails because it throws)
       uint256 public executeProposalPeriod = 10 days;
       
       
       
     


       IERC20 public MoondayToken;

       Uniswapv2Pair public MoondayTokenPair;


       // Proposals to spend the DAO's ether
       Proposal[] public proposals;
      
       // The unix time of the last time quorum was reached on a proposal
       uint public lastTimeMinQuorumMet;

      
       // Map of addresses and proposal voted on by this address
       mapping (address => uint[]) public votingRegister;



        uint256 public V = 2 ether;
        //median fixed
        
        uint256 public W = 40;
        //40% of holders approx
        
        uint256 public B = 5;
        //0.005% vote
        
        uint256 public C = 10;
        //10* 0.005% vote
     

  
       struct Proposal {
           // The address where the `amount` will go to if the proposal is accepted
           address recipient;
           // A plain text description of the proposal
           string description;
           // A unix timestamp, denoting the end of the voting period
           uint votingDeadline;
           // True if the proposal's votes have yet to be counted, otherwise False
           bool open;
           // True if quorum has been reached, the votes have been counted, and
           // the majority said yes
           bool proposalPassed;
           // A hash to check validity of a proposal
           bytes32 proposalHash;
           // Number of Tokens in favor of the proposal
           uint yea;
           // Number of Tokens opposed to the proposal
           uint nay;
           // Simple mapping to check if a shareholder has voted for it
           mapping (address => bool) votedYes;
           // Simple mapping to check if a shareholder has voted against it
           mapping (address => bool) votedNo;
           // Address of the shareholder who created the proposal
           address creator;
       }



       event ProposalAdded(
            uint indexed proposalID,
            address recipient,
            string description
           );
        event Voted(uint indexed proposalID, bool position, address indexed voter);
        event ProposalTallied(uint indexed proposalID, bool result, uint quorum);
       

    // Modifier that allows only shareholders to vote and create new proposals
    modifier onlyTokenholders {
        if (MoondayToken.balanceOf(msg.sender) == 0) revert();
            _;
    }

    constructor  (
        
        IERC20 _moontoken,
        Uniswapv2Pair _MoondayTokenPair
    ) public  {

        MoondayToken = _moontoken;

        MoondayTokenPair = _MoondayTokenPair;

       
        lastTimeMinQuorumMet = block.timestamp;
        
        proposals.push(); // avoids a proposal with ID 0 because it is used

        
    }


    receive() payable external {
       //we should get ether there but I doubt
       revert();
    }

    function newProposal(
        address _recipient,
        string calldata _description,
        bytes calldata _transactionData,
        uint64 _debatingPeriod
    ) onlyTokenholders payable external returns (uint _proposalID) {

        if (_debatingPeriod < minProposalDebatePeriod
            || _debatingPeriod > 8 weeks
            || msg.sender == address(this) //to prevent a 51% attacker to convert the ether into deposit
            )
                revert("error in debating periods");

        uint256 received = determineAm().mul(C);

		
	    
	    MoondayToken.burn(msg.sender, received);
	    
      
       
        
       
        Proposal memory p;
        p.recipient = _recipient;
        p.description = _description;
        p.proposalHash = keccak256(abi.encodePacked(_recipient, _transactionData));
        p.votingDeadline = block.timestamp.add( _debatingPeriod );
        p.open = true;
        //p.proposalPassed = False; // that's default
        p.creator = msg.sender;
        proposals.push(p);
        _proposalID = proposals.length;
       

        emit ProposalAdded(
            _proposalID,
            _recipient,
            _description
        );
    }

    function checkProposalCode(
        uint _proposalID,
        address _recipient,
        bytes calldata _transactionData
    ) view external returns (bool _codeChecksOut) {
        Proposal memory p = proposals[_proposalID];
        return p.proposalHash == keccak256(abi.encodePacked(_recipient, _transactionData));
    }

    function vote(uint _proposalID, bool _supportsProposal) external {
        
        
        //burn md+
        
        uint256 received = determineAm();

		
	    
	    MoondayToken.burn(msg.sender, received);
	    
	    

        Proposal storage p = proposals[_proposalID];

        if (block.timestamp >= p.votingDeadline) {
            revert();
        }

        if (p.votedYes[msg.sender]) {
            revert();
        }

        if (p.votedNo[msg.sender]) {
            revert();
        }
        

        if (_supportsProposal) {
            p.yea += 1;
            p.votedYes[msg.sender] = true;
        } else {
            p.nay += 1;
            p.votedNo[msg.sender] = true;
        }

        votingRegister[msg.sender].push(_proposalID);
        emit Voted(_proposalID, _supportsProposal, msg.sender);
    }




    function executeProposal(
        uint _proposalID,
        bytes calldata _transactionData
    )  external payable  returns (bool _success) {

        Proposal storage p = proposals[_proposalID];

        // If we are over deadline and waiting period, assert proposal is closed
        if (p.open && block.timestamp > p.votingDeadline.add(executeProposalPeriod)) {
            p.open = false;
            return false;
        }

        // Check if the proposal can be executed
        if (block.timestamp < p.votingDeadline  // has the voting deadline arrived?
            // Have the votes been counted?
            || !p.open
            || p.proposalPassed // anyone trying to call us recursively?
            // Does the transaction code match the proposal?
            || p.proposalHash != keccak256(abi.encodePacked(p.recipient, _transactionData))
            )
                revert();

        
        
         // If we are over deadline and waiting period, assert proposal is closed
        if (p.open && now > p.votingDeadline.add(executeProposalPeriod)) {
            p.open = false;
            return false;
        }
        
        
       
        uint quorum = p.yea;




        // Execute result
        if (quorum >= minQuorum() && p.yea > p.nay) {
            // we are setting this here before the CALL() value transfer to
            // assure that in the case of a malicious recipient contract trying
            // to call executeProposal() recursively money can't be transferred
            // multiple times out of the DAO
            
            
            lastTimeMinQuorumMet = block.timestamp;
            
            
            p.proposalPassed = true;

            // this call is as generic as any transaction. It sends all gas and
            // can do everything a transaction can do. It can be used to reenter
            // the DAO. The `p.proposalPassed` variable prevents the call from 
            // reaching this line again
            (bool success, ) = p.recipient.call.value(msg.value)(_transactionData);
            require(success,"big fuckup");

            
        }

        p.open = false;

        // Initiate event
        emit ProposalTallied(_proposalID, _success, quorum);
        return true;
    }


 
   
    //admin like dao functions change median ETH :(
     function changeMedianV(uint256 _V) external {
        
        require(msg.sender == address(this));
         
        V = _V;
     }
     
    //admin like dao functions change % of holders
     function changeHoldersW(uint256 _W) external {
        
        require(msg.sender == address(this));
         
        W = _W;
     }


    //admin like dao functions change % burn vote
     function changeVoteB(uint256 _B) external {
        
        require(msg.sender == address(this));
         
        B = _B;
     }
     
     //admin like dao functions change % burn vote multiplier for proposal
     function changeVoteC(uint256 _C) external {
        
        require(msg.sender == address(this));
         
        C = _C;
     }



     //admin like dao functions change minProposalDebatePeriod
     function changeMinProposalDebatePeriod(uint256 _minProposalDebatePeriod) external {
        
        require(msg.sender == address(this));
         
        minProposalDebatePeriod = _minProposalDebatePeriod;
     }


    //admin like dao functions change executeProposalPeriod
     function changeexecuteProposalPeriod(uint256 _executeProposalPeriod) external {
        
        require(msg.sender == address(this));
         
        executeProposalPeriod = _executeProposalPeriod;
     }
     
     



 

    function minQuorum() public view returns (uint _minQuorum) {
        (uint256 reserve0,uint256 reserve1,) = MoondayTokenPair.getReserves();
   
        uint256 R = ((MoondayToken.totalSupply().div( (V.mul((reserve1.div(reserve0)))))).mul(W)).div(100);
        
        return R;
    }
    
    
     function determineAm() public view returns (uint _amount) {
        uint256 burn = (MoondayToken.totalSupply().mul(B)).div(100000);
        
        return burn;
    }


 

    function numberOfProposals() view external returns (uint _numberOfProposals) {
        // Don't count index 0. It's used by getOrModifyBlocked() and exists from start
        return proposals.length - 1;
    }

  
}