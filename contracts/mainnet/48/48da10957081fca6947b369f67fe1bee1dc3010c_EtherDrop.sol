pragma solidity ^0.4.20;


contract Ownable {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
	address public owner;

    constructor() public { owner = msg.sender; }

    modifier onlyOwner() { require(msg.sender == owner); _; }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Pausable is Ownable {

    event Pause();
	
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() { require(!paused); _; }

    modifier whenPaused() { require(paused); _; }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract EtherDrop is Pausable {

    /*
     * subscription ticket price
     */
    uint priceWei;

    /*
     * subscription queue size: power of 10
     */
	uint qMax;
    
	/*
     * Queue Order - Log10 qMax
     * e.g. random [0 to 999] is of order 3 => rand = 100*x + 10*y + z
     */
	 uint dMax;

	/*
     * log a new subscription
     */
    event NewSubscriber(address indexed addr, uint indexed round, uint place);
    
	/*
     * log a new round - drop out
     */
	event NewDropOut(address indexed addr, uint indexed round, uint place, uint price);
	
	/*
     * round lock - future block hash lock
     */
	uint _lock;
	
	/*
     * last round block
     */
	uint _block;
    
	/*
     * active round
     */
	uint _round; 
	
    /*
     * team support
     */
    uint _collectibles;
	
	/*
     * active subscription queue
     */
	address[] _queue;
	
    /*
     * last user subscriptions
     */
	mapping(address => uint) _userRound;
	
	/*
	 * starting by round one
	 * set round block
	 */
	constructor(uint order, uint price) public {
		
		/* 
		 * queue order and price limits 
		 */
		require(0 < order && order < 4 && price >= 1e16 && price <= 1e18);
		
		/*
		 * queue size
		 */
		dMax = order;
		qMax = 10**order;

        /*
	     * subscription price
	     */
	    priceWei = price;
		
		/*
		 * initial round & block start
		 */
	    _round = 1;
	    _block = block.number;
	}
	
	/*
	 * returns current drop stats: [ round, position, max, price, block, lock]
	 */
    function stat() public view returns (uint round, uint position, uint max, 
        uint price, uint blok, uint lock) {
        return ( _round - (_queue.length == qMax ? 1 : 0), _queue.length, qMax, 
            priceWei, _block, _lock);
    }
	
	/*
	 * returns user&#39;s stats: [last_subscription_round, current_drop_round]
	 */
	function userRound(address user) public view returns (uint lastRound, uint currentRound) {
		return (_userRound[user], _round - (_queue.length == qMax ? 1 : 0));
	}

	/*
	 * fallback subscription
	 */
    function() public payable whenNotPaused {

		/*
		 * contracts are not allowed to participate
		 */
        require(tx.origin == msg.sender && msg.value >= priceWei);
	
		/*
		 * unlock new round condition
		 */
		if (_lock > 0 && block.number >= _lock) {	
			/*
			 * random winner ticket position
			 * block hash number derivation
			 */
			uint _r = dMax;
            uint _winpos = 0;
			bytes32 _a = blockhash(_lock);
			for (uint i = 31; i >= 1; i--) {
				if (uint8(_a[i]) >= 48 && uint8(_a[i]) <= 57) {
					_winpos = 10 * _winpos + (uint8(_a[i]) - 48);
					if (--_r == 0) break;
				}
			}
            
			/*
			 * rewards and collection
			 */
			uint _reward = (qMax * priceWei * 90) / 100;
            _collectibles += address(this).balance - _reward;
			_queue[_winpos].transfer(_reward);
            
			/*
			 * log ether drop event
			 */
			emit NewDropOut(_queue[_winpos], _round - 1, _winpos + 1, _reward);
			
			/*
			 * update the block number
			 */
            _block = block.number;
            
            /*
			 * reset lock
			 */
            _lock = 0;
			
			/*
			 * queue reset
			 */
			delete _queue;
        }
		/*
		 * prevent round Txn(s) in one block overflow
		 */
		else if (block.number + 1 == _lock) {
			revert();
		}
        
		/*
		 * only one address per round
		 */
		require(_userRound[msg.sender] != _round);
		
		/*
		 * set address subscription flag
		 */
		_userRound[msg.sender] = _round;
		
		/*
		 * save subscription
		 */
        _queue.push(msg.sender);

		/*
		 * log ticket subscription event
		 */
        emit NewSubscriber(msg.sender, _round, _queue.length);
        
		/*
		 * new round handler
		 */
        if (_queue.length == qMax) {
            _round++;
            _lock = block.number + 1;
        }
    }

    /*
	 * team R&D support
	 */
    function support() public onlyOwner {
        owner.transfer(_collectibles);
		_collectibles = 0;
    }
}