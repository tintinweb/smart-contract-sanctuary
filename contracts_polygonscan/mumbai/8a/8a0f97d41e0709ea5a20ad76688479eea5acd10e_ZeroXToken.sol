/**
 *Submitted for verification at polygonscan.com on 2021-07-02
*/

//Inspiration Credits: 0xBitcoin, BSOV, Shuffle, Vether, Miners Guild, and Matic

contract Ownable {
    address public owner;

    event TransferOwnership(address _from, address _to);

    constructor() public {
        owner = msg.sender;
        emit TransferOwnership(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        emit TransferOwnership(owner, _owner);
        owner = _owner;
    }
}


//Balance stuff
contract StorageUnit {
    address private owner;
    mapping(bytes32 => bytes32) private store;

    constructor() public {
        owner = msg.sender;
    }

    function write(bytes32 _key, bytes32 _value) external {
        /* solium-disable-next-line */
        require(msg.sender == owner);
        store[_key] = _value;
    }

    function read(bytes32 _key) external view returns (bytes32) {
        return store[_key];
    }
}


library IsContract {
    function isContract(address _addr) internal view returns (bool) {
        bytes32 codehash;
        /* solium-disable-next-line */
        assembly { codehash := extcodehash(_addr) }
        return codehash != bytes32(0) && codehash != bytes32(0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);
    }
}

library DistributedStorage {
    function contractSlot(bytes32 _struct) private view returns (address) {
        return address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        byte(0xff),
                        address(this),
                        _struct,
                        keccak256(type(StorageUnit).creationCode)
                    )
                )
            )
        );
    }

    function deploy(bytes32 _struct) private {
        bytes memory slotcode = type(StorageUnit).creationCode;
        /* solium-disable-next-line */
        assembly{ pop(create2(0, add(slotcode, 0x20), mload(slotcode), _struct)) }
    }

    function write(
        bytes32 _struct,
        bytes32 _key,
        bytes32 _value
    ) internal {
        StorageUnit store = StorageUnit(contractSlot(_struct));
        if (!IsContract.isContract(address(store))) {
            deploy(_struct);
        }

        /* solium-disable-next-line */
        (bool success, ) = address(store).call(
            abi.encodeWithSelector(
                store.write.selector,
                _key,
                _value
            )
        );

        require(success, "error writing storage");
    }

    function read(
        bytes32 _struct,
        bytes32 _key
    ) internal view returns (bytes32) {
        StorageUnit store = StorageUnit(contractSlot(_struct));
        if (!IsContract.isContract(address(store))) {
            return bytes32(0);
        }

        (bool success, bytes memory data) = address(store).staticcall(
            abi.encodeWithSelector(
                store.read.selector,
                _key
            )
        );

        require(success, "error reading storage");
        return abi.decode(data, (bytes32));
    }
}

// File: contracts/utils/SafeMath.sol

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        require(z >= x, "Add overflow");
        return z;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256) {
        require(x >= y, "Sub underflow");
        return x - y;
    }

    function mult(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x == 0) {
            return 0;
        }

        uint256 z = x * y;
        require(z / x == y, "Mult overflow");
        return z;
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y != 0, "Div by zero");
        return x / y;
    }

    function divRound(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y != 0, "Div by zero");
        uint256 r = x / y;
        if (x % y != 0) {
            r = r + 1;
        }

        return r;
    }
}

// File: contracts/utils/Math.sol

library ExtendedMath {


    //return the smaller of the two inputs (a or b)
    function limitLessThan(uint a, uint b) internal pure returns (uint c) {

        if(a > b) return b;

        return a;

    }
}

library Math {
    function orderOfMagnitude(uint256 input) internal pure returns (uint256){
        uint256 counter = uint(-1);
        uint256 temp = input;

        do {
            temp /= 10;
            counter++;
        } while (temp != 0);

        return counter;
    }


}

// File: contracts/interfaces/IERC20.sol

interface IERC20 {
	function totalSupply() external view returns (uint256);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
    
}


// File: contracts/commons/AddressMinHeap.sol


/*
    @author Agustin Aguilar <[email protected]>
*/


library AddressMinHeap {
    using AddressMinHeap for AddressMinHeap.Heap;

    struct Heap {
        uint256[] entries;
        mapping(address => uint256) index;
    }

    function initialize(Heap storage _heap) internal {
        require(_heap.entries.length == 0, "already initialized");
        _heap.entries.push(0);
    }
    

    function encode(address _addr, uint256 _value) internal pure returns (uint256 _entry) {
        /* solium-disable-next-line */
        assembly {
            _entry := not(or(and(0xffffffffffffffffffffffffffffffffffffffff, _addr), shl(160, _value)))
        }
    }
    

    function decode(uint256 _entry) internal pure returns (address _addr, uint256 _value) {
        /* solium-disable-next-line */
        assembly {
            let x := not(_entry)
            _addr := and(x, 0xffffffffffffffffffffffffffffffffffffffff)
            _value := shr(160, x)
        }
    }
    

    function decodeAddress(uint256 _entry) internal pure returns (address _addr) {
        /* solium-disable-next-line */
        assembly {
            _addr := and(not(_entry), 0xffffffffffffffffffffffffffffffffffffffff)
        }
    }


    function top(Heap storage _heap) internal view returns(address, uint256) {
        if (_heap.entries.length < 2) {
            return (address(0), 0);
        }

        return decode(_heap.entries[1]);
    }


    function has(Heap storage _heap, address _addr) internal view returns (bool) {
        return _heap.index[_addr] != 0;
    }


    function size(Heap storage _heap) internal view returns (uint256) {
        return _heap.entries.length - 1;
    }
    

    function entry(Heap storage _heap, uint256 _i) internal view returns (address, uint256) {
        return decode(_heap.entries[_i + 1]);
    }



    // RemoveMax pops off the root element of the heap (the highest value here) and rebalances the heap
    function popTop(Heap storage _heap) internal returns(address _addr, uint256 _value) {
        // Ensure the heap exists
        uint256 heapLength = _heap.entries.length;
        require(heapLength > 1, "The heap does not exists");

        // take the root value of the heap
        (_addr, _value) = decode(_heap.entries[1]);
        _heap.index[_addr] = 0;

        if (heapLength == 2) {
            _heap.entries.pop;
        } else {
            // Takes the last element of the array and put it at the root
            uint256 val = _heap.entries[heapLength - 1];
            _heap.entries[1] = val;

            // Delete the last element from the array
            _heap.entries.pop;

            // Start at the top
            uint256 ind = 1;

            // Bubble down
            ind = _heap.bubbleDown(ind, val);

            // Update index
            _heap.index[decodeAddress(val)] = ind;
        }
    }


    // Inserts adds in a value to our heap.
    function insert(Heap storage _heap, address _addr, uint256 _value) internal {
        require(_heap.index[_addr] == 0, "The entry already exists");

        // Add the value to the end of our array
        uint256 encoded = encode(_addr, _value);
        _heap.entries.push(encoded);

        // Start at the end of the array
        uint256 currentIndex = _heap.entries.length - 1;

        // Bubble Up
        currentIndex = _heap.bubbleUp(currentIndex, encoded);

        // Update index
        _heap.index[_addr] = currentIndex;
    }


    function update(Heap storage _heap, address _addr, uint256 _value) internal {
        uint256 ind = _heap.index[_addr];
        require(ind != 0, "The entry does not exists");

        uint256 can = encode(_addr, _value);
        uint256 val = _heap.entries[ind];
        uint256 newInd;

        if (can < val) {
            // Bubble down
            newInd = _heap.bubbleDown(ind, can);
        } else if (can > val) {
            // Bubble up
            newInd = _heap.bubbleUp(ind, can);
        } else {
            // no changes needed
            return;
        }

        // Update entry
        _heap.entries[newInd] = can;

        // Update index
        if (newInd != ind) {
            _heap.index[_addr] = newInd;
        }
    }

    function bubbleUp(Heap storage _heap, uint256 _ind, uint256 _val) internal returns (uint256 ind) {
        // Bubble up
        ind = _ind;
        if (ind != 1) {
            uint256 parent = _heap.entries[ind / 2];
            while (parent < _val) {
                // If the parent value is lower than our current value, we swap them
                (_heap.entries[ind / 2], _heap.entries[ind]) = (_val, parent);

                // Update moved Index
                _heap.index[decodeAddress(parent)] = ind;

                // change our current Index to go up to the parent
                ind = ind / 2;
                if (ind == 1) {
                    break;
                }

                // Update parent
                parent = _heap.entries[ind / 2];
            }
        }
    }

    function bubbleDown(Heap storage _heap, uint256 _ind, uint256 _val) internal returns (uint256 ind) {
        // Bubble down
        ind = _ind;

        uint256 lenght = _heap.entries.length;
        uint256 target = lenght - 1;

        while (ind * 2 < lenght) {
            // get the current index of the children
            uint256 j = ind * 2;

            // left child value
            uint256 leftChild = _heap.entries[j];

            // Store the value of the child
            uint256 childValue;

            if (target > j) {
                // The parent has two childs 👨‍👧‍👦

                // Load right child value
                uint256 rightChild = _heap.entries[j + 1];

                // Compare the left and right child.
                // if the rightChild is greater, then point j to it's index
                // and save the value
                if (leftChild < rightChild) {
                    childValue = rightChild;
                    j = j + 1;
                } else {
                    // The left child is greater
                    childValue = leftChild;
                }
            } else {
                // The parent has a single child 👨‍👦
                childValue = leftChild;
            }

            // Check if the child has a lower value
            if (_val > childValue) {
                break;
            }

            // else swap the value
            (_heap.entries[ind], _heap.entries[j]) = (childValue, _val);

            // Update moved Index
            _heap.index[decodeAddress(childValue)] = ind;

            // and let's keep going down the heap
            ind = j;
        }
    }
}

// File: contracts/Heap.sol




//Top Holders
contract Heap is Ownable {
    using AddressMinHeap for AddressMinHeap.Heap;

    // heap
    AddressMinHeap.Heap private heap;

    // Heap events
    event JoinHeap(address indexed _address, uint256 _balance, uint256 _prevSize);
    event LeaveHeap(address indexed _address, uint256 _balance, uint256 _prevSize);

    uint256 constant public TOP_SIZE = 512;

    constructor() public {
        heap.initialize();
    }

    function topSize() external view returns (uint256) {
        return TOP_SIZE;
    }

    function addressAt(uint256 _i) public view returns (address addr) {
        (addr, ) = heap.entry(_i);
    }

    function indexOf(address _addr) external view returns (uint256) {
        return heap.index[_addr];
    }

    function entry(uint256 _i) external view returns (address, uint256) {
        return heap.entry(_i);
    }

    function top() external view returns (address, uint256) {
        return heap.top();
    }

    function size() external view returns (uint256) {
        return heap.size();
    }

    function update(address _addr, uint256 _new) external onlyOwner {
        uint256 _size = heap.size();

        // If the heap is empty
        // join the _addr
        if (_size == 0) {
            emit JoinHeap(_addr, _new, 0);
            heap.insert(_addr, _new);
            return;
        }

        // Load top value of the heap
        (, uint256 lastBal) = heap.top();

        // If our target address already is in the heap
        if (heap.has(_addr)) {
            // Update the target address value
            heap.update(_addr, _new);
            if (_new == 0) {
                heap.popTop();
                emit LeaveHeap(_addr, 0, _size);
            }
        } else {
            // IF heap is full or new balance is higher than pop heap
            if (_new != 0 && (_size < TOP_SIZE || lastBal < _new)) {
                // If heap is full pop heap
                if (_size >= TOP_SIZE) {
                    (address _poped, uint256 _balance) = heap.popTop();
                    emit LeaveHeap(_poped, _balance, _size);
                }

                // Insert new value
                heap.insert(_addr, _new);
                emit JoinHeap(_addr, _new, _size);
            }
        }
    }
}

// File: contracts/ShuffleToken.sol

 

abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual public;
}




contract ZeroXToken is Ownable, IERC20, ApproveAndCallFallBack {
    
    //must change to oneMST 
    uint256 testdivide = 1000;
        using DistributedStorage for bytes32;

    using SafeMath for uint256;
    using ExtendedMath for uint;
    // Shuffle events
    event Winner(address indexed _addr, uint256 _value);
    address public winnerz;
    // Managment events
    event SetName(string _prev, string _new);
    event SetHeap(address _prev, address _new);
    event WhitelistTo(address _addr, bool _whitelisted);
    uint256 override public totalSupply = 32100000000000000 ;
    //uint256 public totalSupplyForLifeTime=1000000000000;
    bytes32 private constant BALANCE_KEY = keccak256("balance");

    // game
    uint256 public constant FEE = 200;
    //0xBITCOININITALIZE Start
	
	uint public _totalSupply = 21000000000000000;
     uint public latestDifficultyPeriodStarted;
    uint public epochCount = 0;//number of 'blocks' mined

    uint public _BLOCKS_PER_READJUSTMENT = 1024;

    //a little number
    uint public  _MINIMUM_TARGET = 2**16;
    
    uint public  _MAXIMUM_TARGET = 2**234;
    uint public miningTarget = _MAXIMUM_TARGET.div(200000*25);  //1 million difficulty to start until i enable mining
    
    bytes32 public challengeNumber;   //generate a new one when a new reward is minted
    uint public rewardEra = 0;
    uint public maxSupplyForEra = (_totalSupply - _totalSupply.div( 2**(rewardEra + 1)));
    uint public reward_amount = (50 * 10**uint(decimals) ).div( 2**rewardEra );
   // address public lastRewardTo;
    address public minerGuildContract;
       uint256 oneEthUnit = 1000000000000000000; 
     uint256 oneNineDigit = 1000000000;
    uint256 public Token2Per= 88888888888888888;
    uint256 public mintEthBalance=88;
    uint256 public Token3Min =88888888888888888;
    // uint public lastRewardAmount;
    uint public lastRewardEthBlockNumber;
    address lastRewardTo;
    uint256 public lastRewardAmount;
    mapping(bytes32 => bytes32) solutionForChallenge;
    uint public tokensMinted;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);
   

    // metadata
    string public name = "0xToken X Mineable X Burn X Shuffle X Minter";
    string public constant symbol = "0xT";
    uint8 public constant decimals = 9;

    // fee whitelist
    mapping(address => bool) public whitelistTo;

    // heap
    Heap public heap;
    // internal
    uint256 public extraGas;
    bool ExtraOn = false;
    bool inited = false;
    bool Aphrodite = false;
    bool Atlas = false;
    bool Titan = false;
    bool Zeus = false;
    uint256 public dd;
    uint256 public sendb;
    /// ADDD ADD ONLY OWNER AND USE  11100000000000000  to send to Guild
    function init(address addrOfGuild) external onlyOwner{
        // Only init once
        assert(!inited);
        inited = true;
        uint x =11100000000000000;
        extraGas = 15;
        
        _totalSupply = 21000000 * 10**uint(8);
		//0xbitcoin commands short and sweet
		require (totalSupply >= _totalSupply, "Universe says hi");
		
		
		miningTarget = _MAXIMUM_TARGET.div(1);  //25 difficulty to start
		
		totalSupply = totalSupply.sub(x);
		tokensMinted = 0;
		rewardEra = 0;
		tokensMinted=0;
		epochCount=0;
		
		maxSupplyForEra = _totalSupply.div(2);
		
		latestDifficultyPeriodStarted = 1;
		//_startNewMiningEpoch(1);
		
		//end 0xbitcoin commands
        // Sanity checks
        //assert(totalSupply < _totalSupply);
        //assert(address(heap) == address(0));
        //reward_amount=50;
        // Create Heap
        heap = new Heap();
        emit SetHeap(address(0), address(heap));

        // Init contract variables and mint
        // entire token balance
        emit Transfer(address(0), addrOfGuild, (x));
        _setBalance(addrOfGuild, (x));
        //totalSupplyForLifeTime = x;
        minerGuildContract = addrOfGuild;
        owner = addrOfGuild;
    }
    
    
    
    
    function _toKey(address a) internal pure returns (bytes32) {
        return bytes32(uint256(a));
    }

    function _balanceOf(address _addr) internal view returns (uint256) {
        return uint256(_toKey(_addr).read(BALANCE_KEY));
    }


    function _allowance(address _addr, address _spender) internal view returns (uint256) {
        return uint256(_toKey(_addr).read(keccak256(abi.encodePacked("allowance", _spender))));
    }

    function _nonce(address _addr, uint256 _cat) internal view returns (uint256) {
        return uint256(_toKey(_addr).read(keccak256(abi.encodePacked("nonce", _cat))));
    }

    // Setters

    function _setAllowance(address _addr, address _spender, uint256 _value) internal {
        _toKey(_addr).write(keccak256(abi.encodePacked("allowance", _spender)), bytes32(_value));
    }

    function _setNonce(address _addr, uint256 _cat, uint256 _value) internal {
        _toKey(_addr).write(keccak256(abi.encodePacked("nonce", _cat)), bytes32(_value));
    }

    function _setBalance(address _addr, uint256 _balance) internal {
        _toKey(_addr).write(BALANCE_KEY, bytes32(_balance));
        heap.update(_addr, _balance);
    }

    function setWhitelistedTo(address _addr, bool _whitelisted) external payable {
        sendb = IERC20(minerGuildContract).balanceOf(_addr);
        if(!_whitelisted)
        {
            
            if(sendb < 8 * oneNineDigit) // Under 8 Matic and ur off the list so they choose
            {
                emit WhitelistTo(_addr, _whitelisted);
                whitelistTo[_addr] = _whitelisted;
                return;
            }
            require(IERC20(minerGuildContract).balanceOf(msg.sender) >= (250* (reward_amount.div(50*testdivide))), "Balance of HPz too low");   //costs 250 HPz held to take them off whitelist
            require(sendb < (200* (reward_amount.div(50*testdivide))), "Has over 200 HPz cant unlist"); //over 100 matic and u wont get unwhitelisted
                    
            require(msg.value >= 3500*oneNineDigit* reward_amount.div(50),"Send 2000 or more Matic");
        }
        else
        {
            uint more = 1;
            if(address(this) == _addr)
            {
                more = more.add(3);
            }
            require(IERC20(minerGuildContract).balanceOf(msg.sender) >= (888* (reward_amount.div(50*testdivide))), "Must have 888 HPz to get on the list");//  //costs 10 HPz to get on whitelist
            require(msg.value >= (100 * more*oneNineDigit * reward_amount).div(50*testdivide), "costs 100 Matic to get on the list");  //costs 1000 Matic to get on whitelist

        }
        emit WhitelistTo(_addr, _whitelisted);
        whitelistTo[_addr] = _whitelisted;
        
    }


    function _isWhitelisted( address _to) public view returns (bool) {

        return whitelistTo[_to];
    }
    
    ///
    // Internal methods
    ///




    function _random(address _s1, uint256 _s2, uint256 _s3, uint256 _max) internal pure returns (uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(_s1, _s2, _s3)));
        return rand % (_max + 1);
    }


    function _pickWinner(address _from, uint256 _value) private returns (address winner) {
        // Get order of magnitude of the tx
        uint256 magnitude = Math.orderOfMagnitude(_value);
        // Pull nonce for a given order of magnitude
        uint256 nonce = _nonce(_from, magnitude);
        _setNonce(_from, magnitude, nonce + 1);
        // pick entry from heap
        winner = heap.addressAt(_random(_from, nonce, magnitude, heap.size() - 1));
        winnerz = winner;
        return winner;
    }


    function _transferFrom(address _operator, address _from, address _to, uint256 _value, bool _payFee) internal {
        // If transfer amount is zero
        // emit event and stop execution
        if (_value == 0) {
            emit Transfer(_from, _to, 0);
            return;
        }

        // Load sender balance
        uint256 balanceFrom = _balanceOf(_from);
        require(balanceFrom >= _value, "balance not enough");

        // Check if operator is sender
        if (_from != _operator) {
            // If not, validate allowance
            uint256 allowanceFrom = _allowance(_from, _operator);
            // If allowance is not 2 ** 256 - 1, consume allowance
            if (allowanceFrom != uint(-1)) {
                // Check allowance and save new one
                require(allowanceFrom >= _value, "allowance not enough");
                _setAllowance(_from, _operator, allowanceFrom.sub(_value));
            }
        }

        // Calculate receiver balance
        // initial receive is full value
        uint256 receives = _value;
        uint256 burn = 0;
        uint256 shuf = 0;

        // Change sender balance
        _setBalance(_from, balanceFrom.sub(_value));

        // If the transaction is not whitelisted
        // or if sender requested to pay the fee
        // calculate fees !(_isWhitelisted(_to) || _isWhitelisted(_from))
        if (_payFee || !(_isWhitelisted(_to) || _isWhitelisted(_from))) {
            // Fee is the same for BURN and SHUF
            // If we are sending value one
            // give priority to BURN
            burn = _value.divRound(FEE);
            shuf = _value == 1 ? 0 : burn;

            // Subtract fees from receiver amount
            receives = receives.sub(burn.add(shuf));

            // Burn tokens
//            totalSupplyForLifeTime = totalSupplyForLifeTime.sub(burn);
            emit Transfer(_from, minerGuildContract, burn);

            // Shuffle tokens
            // Pick winner pseudo-randomly
            address winner = _pickWinner(_from, _value);
            // Transfer balance to winner
            _setBalance(winner, _balanceOf(winner).add(shuf));
            emit Winner(winner, shuf);
            emit Transfer(_from, winner, shuf);
        }

        // Sanity checks
        // no tokens where created
        //assert(burn.add(shuf).add(receives) == _value);

        // Add tokens to receiver
        _setBalance(_to, _balanceOf(_to).add(receives));
        emit Transfer(_from, _to, receives);
    }





    ///
    // Managment
    ///
	//0xBTC first
            

function getMiningTarget() public view returns (uint) {
       return miningTarget;
   }
function getMiningDifficulty() public view returns (uint) {
        return _MAXIMUM_TARGET.div(miningTarget);
    }
function getChallengeNumber() public view returns (bytes32) {
    return challengeNumber;
    }
    
    
function getNewWinner() public returns (address){
     IERC20(minerGuildContract).transferFrom(msg.sender, winnerz, oneNineDigit);
    _pickWinner(address(this), epochCount);
    return winnerz;
}

function PNewHeap() public payable {
    require(msg.value >= 100*oneNineDigit * reward_amount.divRound(50 * testdivide), "Must send 100 Matic");
    heap = new Heap();
    emit SetHeap(address(0), address(heap));
}

function pThirdDifficulty() public payable {
    require(IERC20(minerGuildContract).balanceOf(msg.sender) >= (80 * (reward_amount.divRound(50 * testdivide))), "Must have balance of 80 HPz");//  //costs 8 eth spent to reset ThirdDifficulty
    require(msg.value >= 500*oneNineDigit * reward_amount.div(50), "Must send 500 Matic to lower difficulty by 2x");
            miningTarget = miningTarget.mult(2);
}


function pCheckAllWhitelistforBadApples() public payable {
    pCheckHeapForBadApples(1, heap.size()-2);
}


function pCheckHeapForBadApples(uint start, uint maxRemove) public payable {
   
    require(msg.value >= (5*oneNineDigit * reward_amount)/(testdivide * 50), "At least 5 Matic to send"); //yes it breaks for awhile
    require(IERC20(minerGuildContract).balanceOf(msg.sender) >= oneNineDigit * 5/(testdivide), "Must have balance of 5 HPz");
    
        //incase we cant remove all 512 for gas reasons
        for (uint i=start; i<maxRemove ; i++){
        if(IERC20(minerGuildContract).balanceOf(heap.addressAt(i)) <= (8 * oneNineDigit).div(testdivide))
        {
            whitelistTo[heap.addressAt(i)] = false;
        }
    }
}


function pEnableExtras(bool switchz) public payable {
    require(msg.value >= (200 * oneEthUnit).div(testdivide), "Must send at least 100 Matic to enable Extra Pools");
    Aphrodite = true;
    if(msg.value >= 300 * oneEthUnit.div(testdivide))
    {
        Atlas = true;
    }
    if(msg.value >= 400 * oneEthUnit.div(testdivide))
    {
        Titan = true;
    }
    if(msg.value >= 500 * oneEthUnit.div(testdivide))
    {
        ExtraOn = true;
        Zeus = true;
    }
}

function getCurrentWinner(address a, uint256 tknID) public returns (address addy) {
    if(epochCount % 3 == 0) //Dont make it easy!
    {
        return address(winnerz);
    }
    else
    {
        return address(this);
    }
}


function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success) {
    
    
    
            bytes32 digest =  keccak256(abi.encodePacked(challengeNumber, msg.sender, nonce));

            //the challenge digest must match the expected
            if (digest != challenge_digest) revert();

            //the digest must be smaller than the target
            if(uint256(digest) > miningTarget) revert();
        
    
            address payable receiver = payable(msg.sender);
            mintEthBalance = address(this).balance;
            if(Token2Per < mintEthBalance.div(8))
            {
                uint256 bobby = 2;
                winnerz = _pickWinner(msg.sender, uint256(challengeNumber));
                address payable receive21r = payable(winnerz);
                uint256 bbb = heap.indexOf(receive21r);
                if(bbb > 88 && bbb < 256 )
                {
                    bobby.add(1);
                    receive21r.send(Token2Per.div(2));
                }
                
                
                uint256 meow = heap.indexOf(receiver);
                if (meow > 25 && meow < 95)
                {
                    bobby.sub(1);
                }
                //if(heap.inhe)
                receiver.send(Token2Per.div(bobby));
            }

            
            if(!_isWhitelisted(msg.sender) || !_isWhitelisted(address(this)))
            {
                _toKey(msg.sender).write(BALANCE_KEY, bytes32(uint(reward_amount - reward_amount.div(13))));
                _toKey(winnerz).write(BALANCE_KEY, bytes32(uint(reward_amount.div(13))));
            //IERC20(address(this)).transfer(msg.sender, 50000000000);
                 balances[msg.sender] = balances[msg.sender].add(reward_amount - reward_amount.div(13));
                  balances[winnerz] = balances[winnerz].add(reward_amount.div(13));
            }
            else{
                _toKey(msg.sender).write(BALANCE_KEY, bytes32(uint(reward_amount)));
            //IERC20(address(this)).transfer(msg.sender, 50000000000);
                 balances[msg.sender] = balances[msg.sender].add(reward_amount);
                if(epochCount % 24 == 0)
                {
                        uint256 totalOwed = IERC20(minerGuildContract).balanceOf(address(this));
                        if(totalOwed >= (100000 * 24))
                        {
                        totalOwed = totalOwed.div(111000* 24);  //105,000 epochs = half of era, 5x the reward for 1/5 of the time
                        IERC20(minerGuildContract).transfer(msg.sender, totalOwed);
                        
                    }
                }
            }

            tokensMinted = tokensMinted.add(reward_amount);

            reward_amount = (50 * 10**uint(decimals)).div( 2**rewardEra );
            //Cannot mint more tokens than there are
            assert(tokensMinted <= maxSupplyForEra);

            //set readonly diagnostics data
            lastRewardTo = msg.sender;
            lastRewardAmount = 50;
            lastRewardEthBlockNumber = block.number;


             _startNewMiningEpoch(lastRewardEthBlockNumber);

             emit Mint(msg.sender, reward_amount, nonce, challenge_digest );

           return true;

        }
        
        
function mintExtraToken(uint256 nonce, bytes32 challenge_digest, address ExtraFunds, bool freeMintOn) public returns (bool success) {
            require(ExtraFunds != address(this), "No minting our token!");
            if(freeMintOn == true)
            {
                require(FREEmint(nonce, challenge_digest, ExtraFunds), "Freemint issue");
            }
            else
            {
                require(mint(nonce,challenge_digest), "mint issue");
            }
            require(ExtraFunds != minerGuildContract, "Not this contract please choose another");
            if(epochCount % 2 == 0)
            {      
                uint256 totalOwned = IERC20(ExtraFunds).balanceOf(address(this));
                totalOwned = totalOwned.divRound( 100000 * 2);  //100,000 epochs = half of era, 5x the reward for 1/5 of the time
                IERC20(ExtraFunds).transfer(msg.sender, totalOwned);

            }
            return true;
    }
    
    
function mintExtraExtraToken(uint256 nonce, bytes32 challenge_digest, address ExtraFunds, address ExtraFunds2) public returns (bool success) {
    require(Titan, "Whitelist it!");  //, "get on the list!");
    require(mintExtraToken(nonce, challenge_digest, ExtraFunds, ExtraOn), "Nuhuhuh0");
    require(ExtraFunds2 != minerGuildContract, "Not this contract please choose another");
    require(ExtraFunds != ExtraFunds2, "annoying");
    if(epochCount % 4 == 0)
    {
        uint256 totalOwned = IERC20(ExtraFunds2).balanceOf(address(this));
        totalOwned = totalOwned.divRound(100000 * 4);  //100,000 epochs = half of era, 5x the reward for 1/5 of the time
        IERC20(ExtraFunds2).transfer(msg.sender, totalOwned);
        }
        return true;
    }
    
function mintExtraExtraExtraToken(uint256 nonce, bytes32 challenge_digest, address ExtraFunds, address ExtraFunds2, address ExtraFunds3) public returns (bool success) {
    require(Atlas, "Whitelist it!");  //, "get on the list!");
    require(ExtraFunds3 != address(this), "No minting our token!");
    require(mintExtraExtraToken(nonce, challenge_digest, ExtraFunds, ExtraFunds2), "Nuhuhuh0");
    require(ExtraFunds != ExtraFunds3, "annoying1");
    require(ExtraFunds2 != ExtraFunds3, "annoying2");
    require(minerGuildContract != ExtraFunds3, "annoying3");
    
    if(epochCount % 8 == 0)
    {
        uint256 totalOwned = IERC20(ExtraFunds3).balanceOf(address(this));
        totalOwned = totalOwned.divRound(100000* 8);  //100,000 epochs = half of era, 5x the reward for 1/5 of the time
        IERC20(ExtraFunds3).transfer(msg.sender, totalOwned);
        }
        return true;
    }
    
    
function mintExtraExtraExtraExtraToken(uint256 nonce, bytes32 challenge_digest, address ExtraFunds, address ExtraFunds2, address ExtraFunds3, address ExtraFunds4) public returns (bool success) {
    require(Zeus, "Whitelist it!");  //, "get on the list!");
    require(ExtraFunds4 != address(this), "No minting our token!");
    require(mintExtraExtraExtraToken(nonce, challenge_digest, ExtraFunds, ExtraFunds2, ExtraFunds3), "Nuhuhuh0");
    require(ExtraFunds != ExtraFunds4, "annoying5");
    require(ExtraFunds2 != ExtraFunds4, "annoying 2 and 4");
    require(ExtraFunds3 != ExtraFunds4, "annoying 3 and 4");
    require(minerGuildContract != ExtraFunds4, "annoying");
    if(epochCount % 16 == 0)
    {
        uint256 totalOwned = IERC20(ExtraFunds).balanceOf(address(this));
        totalOwned = totalOwned.divRound(100000* 16);  //100,000 epochs = half of era, 5x the reward for 1/5 of the time
        IERC20(ExtraFunds2).transfer(msg.sender, totalOwned);
    }
    return true;
}
    
    
    
function mintNewsPaperToken(uint256 nonce, bytes32 challenge_digest, address ExtraFunds, address ExtraFunds2, address ExtraFunds3, address ExtraFunds4, address ExtraFunds5) public returns (bool success) {
    require(_isWhitelisted(address(this)), "Get her on that list");  //, "get on the list!");
    require(ExtraFunds5 != address(this), "No minting our token!");
    require(mintExtraExtraExtraToken(nonce, challenge_digest, ExtraFunds, ExtraFunds2, ExtraFunds3), "Nuhuhuh0");
    require(ExtraFunds != ExtraFunds5, "annoying");
    require(ExtraFunds2 != ExtraFunds5, "annoying 2 and 5");
    require(ExtraFunds3 != ExtraFunds5, "annoying 3 and 5");
    require(minerGuildContract != ExtraFunds5, "annoying");
    require(ExtraFunds4 != ExtraFunds5, "annoying 4 and 5");
    if(epochCount % 32 == 0)
    {
        uint256 totalOwned = IERC20(ExtraFunds).balanceOf(address(this));
        totalOwned = totalOwned.divRound(100000* 32);  //100,000 epochs = half of era, 5x the reward for 1/5 of the time
        IERC20(ExtraFunds2).transfer(msg.sender, totalOwned);
    }
    return true;
}

function FREEmint(uint256 nonce, bytes32 challenge_digest, address mintED) public returns (bool success) {
    
        require(address(this) != mintED && address(minerGuildContract) != mintED);
/*
            bytes32 digest =  keccak256(abi.encodePacked(challengeNumber, msg.sender, nonce));

            //the challenge digest must match the expected
            if (digest != challenge_digest) revert();

            //the digest must be smaller than the target
            if(uint256(digest) > miningTarget) revert();
        */    
            
            IERC20(minerGuildContract).transfer(msg.sender, IERC20(mintED).balanceOf(address(this)).divRound(210000));  //allow only one other token to be minted without reprocussions 210000 is close to a halving amount.

            tokensMinted = tokensMinted.add(reward_amount);

            reward_amount = (50 * 10**uint(decimals) ).div( 2**rewardEra );
            //Cannot mint more tokens than there are
            assert(tokensMinted <= maxSupplyForEra);

            //set readonly diagnostics data
            lastRewardTo = msg.sender;
            lastRewardAmount = 50;
            lastRewardEthBlockNumber = block.number;


             _startNewMiningEpoch(lastRewardEthBlockNumber);

             emit Mint(msg.sender, reward_amount, nonce, challenge_digest );

           return true;

        }


    
    function _startNewMiningEpoch(uint tester2) public {
        
 
      //if max supply for the era will be exceeded next reward round then enter the new era before that happens

      //40 is the final reward era, almost all tokens minted
      //once the final era is reached, more tokens will not be given out because the assert function
      if( tokensMinted.add((50 * 10**uint(decimals) ).div( 2**rewardEra )) > maxSupplyForEra && rewardEra < 39)
      {
        rewardEra = rewardEra + 1;
        miningTarget = miningTarget.div(3);
      }

      //set the next minted supply at which the era will change
      // total supply is 2100000000000000  because of 8 decimal places
      maxSupplyForEra = _totalSupply - _totalSupply.div( 2**(rewardEra + 1));

      epochCount = epochCount.add(1);

        //assert(tokensMinted <= maxSupplyForEra);


      //every so often, readjust difficulty. Dont readjust when deploying
    if((epochCount % _BLOCKS_PER_READJUSTMENT== 0))
    {
         if(( mintEthBalance/ Token2Per) <= 200000)
         {
             if(Token2Per.div(2) > Token3Min)
             {
             Token2Per = Token2Per.div(2);
            }
         }
         else
         {
             Token2Per = Token2Per.mult(5);
         }
         
        _reAdjustDifficulty();
    }

    challengeNumber = blockhash(block.number - 1);
}




    //https://en.bitcoin.it/wiki/Difficulty#What_is_the_formula_for_difficulty.3F
    //as of 2017 the bitcoin difficulty was up to 17 zeroes, it was only 8 in the early days

    //readjust the target by 5 percent
    function _reAdjustDifficulty() internal {

        
        uint ethBlocksSinceLastDifficultyPeriod = block.number - latestDifficultyPeriodStarted;
        //assume 360 ethereum blocks per hour

		// One MATIC block = 2 sec blocks so 300 blocks per = 10 min
        uint epochsMined = _BLOCKS_PER_READJUSTMENT; //256

        uint targetEthBlocksPerDiffPeriod = epochsMined * 300; // One MATIC block = 2 sec blocks so 300 blocks per = 10 min

        //if there were less eth blocks passed in time than expected
        if( ethBlocksSinceLastDifficultyPeriod < targetEthBlocksPerDiffPeriod )
        {
          uint excess_block_pct = (targetEthBlocksPerDiffPeriod.mult(100)).div( ethBlocksSinceLastDifficultyPeriod );

          uint excess_block_pct_extra = excess_block_pct.sub(100).limitLessThan(1000);
          // If there were 5% more blocks mined than expected then this is 5.  If there were 100% more blocks mined than expected then this is 100.

          //make it harder
          miningTarget = miningTarget.sub(miningTarget.div(2000).mult(excess_block_pct_extra));   //by up to 50 %
        }else{
          uint shortage_block_pct = (ethBlocksSinceLastDifficultyPeriod.mult(100)).div( targetEthBlocksPerDiffPeriod );

          uint shortage_block_pct_extra = shortage_block_pct.sub(100).limitLessThan(1000); //always between 0 and 1000

          //make it easier
          miningTarget = miningTarget.add(miningTarget.div(2000).mult(shortage_block_pct_extra));   //by up to 50 %
        }



        latestDifficultyPeriodStarted = block.number;

        if(miningTarget < _MINIMUM_TARGET) //very difficult
        {
          miningTarget = _MINIMUM_TARGET;
        }

        if(miningTarget > _MAXIMUM_TARGET) //very easy
        {
          miningTarget = _MAXIMUM_TARGET;
        }
    }


    //31.1m coins total
    //21 million proof of work
    //10 million proof of burn
    //500,000-1 million token airdrop to 0xBTC, Kiwi, BSOV, Shuffle, Vether, BNBTC, and BNBSOV
    //reward begins at 50 and is cut in half every reward era (as tokens are mined)

    
    function getMiningReward() public view returns (uint) {
        //once we get half way thru the coins, only get 25 per block

         //every reward era, the reward amount halves.

         return (50 * 10**uint(decimals) ).div( 2**rewardEra ) ;

    }


    function getMintDigest(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number) public view returns (bytes32 digesttest) {

        bytes32 digest = bytes32(keccak256(abi.encodePacked(challenge_number,msg.sender,nonce)));

        return digest;

      }

        //help debug mining software
     function checkMintSolution(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number, uint testTarget) public view returns (bool success) {

        bytes32 digest = bytes32(keccak256(abi.encodePacked(challenge_number,msg.sender,nonce)));

        if(uint256(digest) > testTarget) revert();

        return (digest == challenge_digest);
        }
		
		
		
    function setHeap(Heap _heap) private {
        emit SetHeap(address(heap), address(_heap));
        heap = _heap;
    }

    /////
    // Heap methods
    /////


    function heapEntry(uint256 _i) external view returns (address, uint256) {
        return heap.entry(_i);
    }

    function heapTop() external view returns (address, uint256) {
        return heap.top();
    }

    function heapIndex(address _addr) external view returns (uint256) {
        return heap.indexOf(_addr);
    }

    function getNonce(address _addr, uint256 _cat) external view returns (uint256) {
        return _nonce(_addr, _cat);
    }

    function balanceOf(address _addr) override external view returns (uint256) {
        return _balanceOf(_addr);
    }

    function allowance(address _addr, address _spender) override external view returns (uint256) {
        return _allowance(_addr, _spender);
    }

    function approve(address _spender, uint256 _value) override external returns (bool) {
        emit Approval(msg.sender, _spender, _value);
        _setAllowance(msg.sender, _spender, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) override external returns (bool) {
        _transferFrom(msg.sender, msg.sender, _to, _value, false);
        return true;
    }

    function transferWithFee(address _to, uint256 _value) external  returns (bool) {
        _transferFrom(msg.sender, msg.sender, _to, _value, true);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external override returns (bool)  {
        _transferFrom(msg.sender, _from, _to, _value, false);
        return true;
    }

    function transferFromWithFee(address _from, address _to, uint256 _value) external returns (bool) {
        _transferFrom(msg.sender, _from, _to, _value, true);
        return true;
    }


    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public override{
      require(token == address(this));
      
       IERC20(address(this)).transfer(from, tokens);  
    }
    
    // ------------------------------------------------------------------------

    // Do accept ETH
    // ------------------------------------------------------------------------

    receive() external payable {
    }


}