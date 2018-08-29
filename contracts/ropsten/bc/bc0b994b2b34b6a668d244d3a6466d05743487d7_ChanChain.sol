pragma solidity 0.4.24;

/// @title A 4chan inspired simple imageboard for Ethereum
/// @author Anant Upadhyay
/// @notice A simple imageboard tracking the last 32 active threads
contract ChanChain {

	// For setting owner
	address private owner;

	//Circuit Breaker for pausing the contract
	bool public isPaused = false;

	// Owner can set fees
	uint256 public feeNewThread;
	uint256 public feeReplyThread;

	// Thread Structure
	struct thread {
		string text;
		string ipfsHash;

		uint256 indexLastReply;
		uint256 indexFirstReply;

		uint256 timestamp;
	}

	//Keeping track of threads
	mapping (uint256 => thread) public threads;
	uint256 public indexThreads = 1;

	// Reply structure
	struct reply {
		string text;
		string ipfsHash;

		uint256 replyTo;
		uint256 nextReply;

		uint256 timestamp;
	}

	//Keeping track of replies
	mapping (uint256 => reply) public replies;
	uint256 public indexReplies = 1;

	// Keeping track of last 32 active threads
	uint256[32] public lastThreads;
	// Keeping track of index of the thread that was added last in lastThreads
	uint256 public indexLastThreads = 0;

	//
	// Events
	//

	event newThreadEvent(uint256 threadId, string text, string ipfsHash, uint256 timestamp);
	event newReplyEvent(uint256 replyId, uint256 replyTo, string text, string ipfsHash, uint256 timestamp);

	//
	// Modifiers
	//

/// @dev Create a modifer that checks if the msg.sender is the owner of the contract
	  modifier onlyOwner() {
	    require (msg.sender == owner);
	    _;
	  }

/// @dev Create a modifer that checks if the msg.value is greater than the fee required to create thread
		modifier payFeeNewThread() {
			require(msg.value >= feeNewThread);
			_;
		}
/// @dev Create a modifer that checks if the msg.value is greater than the fee required to reply
		modifier payFeeReplyThread() {
			require(msg.value >= feeReplyThread);
			_;
		}

/// @dev Create a modifer that checks if the contract is paused
		modifier isHalted() {
			require(isPaused == false);
			_;
		}

	//
	// Constructor
	//

/// @dev Set initial fee while deploying the contract
/// @param _feeNewThread Fee required to create new thread (uint256)
/// @param _feeReplyThread Fee required for replying to a thread (uint256)
	constructor(uint256 _feeNewThread, uint256 _feeReplyThread) public {
		owner = msg.sender;
		feeNewThread = _feeNewThread;
		feeReplyThread = _feeReplyThread;
	}

/// @notice Owner can pause the contract
/// @dev Owner can call this function to toggle contract isPaused state
	function toggleContractActive()
	onlyOwner
	public
	returns(bool)
	{
	    isPaused = !isPaused;
			return isPaused;
	}

	/// @notice Owner can kill the contract
	/// @dev Owner can call this function to invoke self destruction and transfer the balance
	function isKill() public onlyOwner{
      selfdestruct(owner);
	}

/// @notice Owner can reset fee in the future
/// @dev Sets feeNewThread and feeReplyThread
/// @param _feeNewThread Fee required to create new thread (uint256)
/// @param  _feeReplyThread Fee required for replying to a thread (uint256)
	function setFees(uint256 _feeNewThread, uint256 _feeReplyThread) public onlyOwner {
		feeNewThread = _feeNewThread;
		feeReplyThread = _feeReplyThread;
	}

	// To get the money back
/// @notice Owner can withdraw fee from contract
/// @dev Transfers all ether in contract to owner
/// @param _amount Amount to withdraw from contract (uint256)
	function withdraw(uint256 _amount)
	public
	onlyOwner
	isHalted
	{
		owner.transfer(_amount);
	}

	// Create a Thread
/// @notice Create a new thread if the fees is paid
/// @dev Creates a new thread, updates last active thread index
/// @param _text Text content for the thread post (string)
/// @param _ipfsHash IPFS hash of image (string)
	function createThread(string _text, string _ipfsHash)
	payable
	public
	payFeeNewThread
	isHalted {
		// Calculate a new thread ID and post
		threads[indexThreads] = thread(_text, _ipfsHash, 0, 0, now);
		// Add it to our last active threads array
		lastThreads[indexLastThreads] = indexThreads;
		// Increment index
		indexLastThreads = addmod(indexLastThreads, 1, 32);
		// Fire Event log
		emit newThreadEvent(indexThreads, _text, _ipfsHash, now);
		// Increment index for next thread
		indexThreads += 1;
	}

	// Reply to a thread
/// @notice Reply to a thread if the fees is paid
/// @dev Replies to a thread after making sure it exists, updates last active thread index
/// @param _replyTo Index of the thread associated with this reply
/// @param _text Text content for the thread post (string), _ipfsHash IPFS hash of image (string)
	function replyThread(uint256 _replyTo, string _text, string _ipfsHash)
	payable
	public
	payFeeReplyThread
	isHalted {
		// Make sure you can&#39;t reply to an nonexistant thread
		require(_replyTo < indexThreads && _replyTo > 0);
		// Post the reply with nextReply = 0 as this is the last message in the chain
		replies[indexReplies] = reply(_text, _ipfsHash, _replyTo, 0, now);
		// Update the thread
		// We&#39;re first to reply
		if(threads[_replyTo].indexFirstReply == 0){
			threads[_replyTo].indexFirstReply = indexReplies;
			threads[_replyTo].indexLastReply = indexReplies;
		}
		// We&#39;re not first to reply so we update the previous reply as well
		else {
			replies[threads[_replyTo].indexLastReply].nextReply = indexReplies;
			threads[_replyTo].indexLastReply = indexReplies;
		}

		// Update the last active threads
		for (uint8 i = 0; i < 32; i++) {
			if(lastThreads[i] == _replyTo) {
				// Already in the list
				break;
			}
			if(i == 31) {
				lastThreads[indexLastThreads] = _replyTo;
				indexLastThreads = addmod(indexLastThreads, 1, 32);
			}
		}
		// Fire Event log
		emit newReplyEvent(indexReplies, _replyTo, _text, _ipfsHash, now);
		// Increment index for next reply
		indexReplies += 1;
	}
}