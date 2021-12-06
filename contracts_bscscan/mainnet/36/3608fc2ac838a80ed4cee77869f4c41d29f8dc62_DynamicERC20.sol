/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

// File: bSwap-v2-core/contracts/interfaces/IDynamicCallee.sol

pragma solidity >=0.5.0;



interface IDynamicCallee {

    function DynamicCall(address sender, uint amount0, uint amount1, bytes calldata data) external;

}


// File: bSwap-v2-core/contracts/interfaces/IDynamicFactory.sol

pragma solidity >=0.5.0;



interface IDynamicFactory {

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);



    function uniV2Router() external view returns (address);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);



    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);



    function createPair(address tokenA, address tokenB) external returns (address pair);



    //function setFeeTo(address) external;

    function setFeeToSetter(address) external;



    function mintReward(address to, uint amount) external;

    function swapFee(address token0, address token1, uint fee0, uint fee1) external returns(bool);

    function setVars(uint varId, uint32 value) external;

    function setRouter(address _router) external;

    function setReimbursementContractAndVault(address _reimbursement, address _vault) external;

    function claimFee() external returns (uint256);

    function getColletedFees() external view returns (uint256 feeAmount);

}


// File: bSwap-v2-core/contracts/interfaces/IERC20.sol

pragma solidity >=0.5.0;



interface IERC20 {

    event Approval(address indexed owner, address indexed spender, uint value);

    event Transfer(address indexed from, address indexed to, uint value);



    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);



    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);



    function mint(address to, uint256 amount) external returns (bool);

}


// File: bSwap-v2-core/contracts/libraries/UQ112x112.sol

pragma solidity =0.5.16;



// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))



// range: [0, 2**112 - 1]

// resolution: 1 / 2**112



library UQ112x112 {

    uint224 constant Q112 = 2**112;



    // encode a uint112 as a UQ112x112

    function encode(uint112 y) internal pure returns (uint224 z) {

        z = uint224(y) * Q112; // never overflows

    }



    // divide a UQ112x112 by a uint112, returning a UQ112x112

    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {

        z = x / uint224(y);

    }

}


// File: bSwap-v2-core/contracts/libraries/Math.sol

pragma solidity =0.5.16;



// a library for performing various math operations



library Math {

    function min(uint x, uint y) internal pure returns (uint z) {

        z = x < y ? x : y;

    }



    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)

    function sqrt(uint y) internal pure returns (uint z) {

        if (y > 3) {

            z = y;

            uint x = y / 2 + 1;

            while (x < z) {

                z = x;

                x = (y / x + x) / 2;

            }

        } else if (y != 0) {

            z = 1;

        }

    }

}


// File: bSwap-v2-core/contracts/libraries/SafeMath.sol

pragma solidity =0.5.16;



// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)



library SafeMath {

    function add(uint x, uint y) internal pure returns (uint z) {

        require((z = x + y) >= x, 'ds-math-add-overflow');

    }



    function sub(uint x, uint y) internal pure returns (uint z) {

        require((z = x - y) <= x, 'ds-math-sub-underflow');

    }



    function mul(uint x, uint y) internal pure returns (uint z) {

        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');

    }

}


// File: bSwap-v2-core/contracts/interfaces/IDynamicERC20.sol

pragma solidity >=0.5.0;



interface IDynamicERC20 {

    event Approval(address indexed owner, address indexed spender, uint value);

    event Transfer(address indexed from, address indexed to, uint value);



    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);



    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);



    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);



    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

}


// File: bSwap-v2-core/contracts/DynamicERC20.sol

pragma solidity =0.5.16;





contract DynamicERC20 is IDynamicERC20 {

    using SafeMath for uint;



    //address public factory;

    uint public rewardTokens;

    uint lastUpdate;

    uint totalWeight;

    mapping(address => uint) public stakingStart;

    mapping(address => uint) public stakingWeight;



    string public constant name = 'dynamic V2';

    string public constant symbol = 'dynamic-V2';

    uint8 public constant decimals = 18;

    uint  public totalSupply;

    mapping(address => uint) public balanceOf;

    mapping(address => mapping(address => uint)) public allowance;



    bytes32 public DOMAIN_SEPARATOR;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    mapping(address => uint) public nonces;

    mapping(address => uint) public locked;   // lock token until end of voting (timestamp)



    event Approval(address indexed owner, address indexed spender, uint value);

    event Transfer(address indexed from, address indexed to, uint value);



    function initialize() internal {

        uint chainId;

        assembly {

            chainId := chainid

        }

        DOMAIN_SEPARATOR = keccak256(

            abi.encode(

                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),

                keccak256(bytes(name)),

                keccak256(bytes('1')),

                chainId,

                address(this)

            )

        );

        //super.initialize();

    }



    function _updateTotalWeight() internal {

        uint _lastUpdate = lastUpdate;

        if (_lastUpdate < block.timestamp) {

            totalWeight = totalWeight.add(

                (block.timestamp.sub(_lastUpdate))  // time interval

                .mul(totalSupply.sub(balanceOf[address(0)])) // total supply without address(0) balance

            );

            lastUpdate = block.timestamp;

        }

    }

    

    function _getWeight(address user) internal view returns (uint weight) {

        uint start = stakingStart[user];

        if (start != 0) {

            weight = stakingWeight[user].add(

                (block.timestamp.sub(start))    // time interval

                .mul(balanceOf[user])

            );

        }

    }



    function _mint(address to, uint value) internal {

        _updateTotalWeight();

        if (to != address(0)) {

            stakingWeight[to] = _getWeight(to);

            stakingStart[to] = block.timestamp;

        }

        totalSupply = totalSupply.add(value);

        balanceOf[to] = balanceOf[to].add(value);

        emit Transfer(address(0), to, value);

    }



    function _burn(address from, uint value) internal returns (uint rewardAmount) {

        _updateTotalWeight();

        uint weight = _getWeight(from);

        uint unstake = weight.mul(value) / balanceOf[from]; // unstake weight is proportional of value

        stakingWeight[from] = weight.sub(unstake);

        stakingStart[from] = block.timestamp;

        rewardAmount = rewardTokens.mul(unstake) / totalWeight;

        rewardTokens = rewardTokens.sub(rewardAmount);

        totalWeight = totalWeight.sub(unstake);

        balanceOf[from] = balanceOf[from].sub(value);

        totalSupply = totalSupply.sub(value);

        emit Transfer(from, address(0), value);

    }



    function _approve(address owner, address spender, uint value) private {

        allowance[owner][spender] = value;

        emit Approval(owner, spender, value);

    }



    function _transfer(address from, address to, uint value) private {

        require(locked[from] < block.timestamp, "LP locked until end of voting");

        _updateTotalWeight();

        uint weight = _getWeight(from);

        uint transferWeight = weight.mul(value) / balanceOf[from]; // transferWeight is proportional of transferring value

        stakingWeight[from] = weight - transferWeight;

        stakingStart[from] = block.timestamp;

        stakingWeight[to] = _getWeight(to) + transferWeight;

        stakingStart[to] = block.timestamp;



        balanceOf[from] = balanceOf[from].sub(value);

        balanceOf[to] = balanceOf[to].add(value);

        emit Transfer(from, to, value);

    }



    function getRewards(address user) external view returns (uint) {

        uint _totalWeight = totalWeight.add(

            (block.timestamp.sub(lastUpdate))  // time interval

            .mul(totalSupply.sub(balanceOf[address(0)])) // total supply without address(0) balance

        );

        uint weight = stakingWeight[user].add(

            (block.timestamp.sub(stakingStart[user]))    // time interval

            .mul(balanceOf[user])

        );

        return rewardTokens.mul(weight) / _totalWeight;

    }







    function approve(address spender, uint value) external returns (bool) {

        _approve(msg.sender, spender, value);

        return true;

    }



    function transfer(address to, uint value) external returns (bool) {

        _transfer(msg.sender, to, value);

        return true;

    }



    function transferFrom(address from, address to, uint value) external returns (bool) {

        if (allowance[from][msg.sender] != uint(-1)) {

            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);

        }

        _transfer(from, to, value);

        return true;

    }



    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {

        require(deadline >= block.timestamp, 'Dynamic: EXPIRED');

        bytes32 digest = keccak256(

            abi.encodePacked(

                '\x19\x01',

                DOMAIN_SEPARATOR,

                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))

            )

        );

        address recoveredAddress = ecrecover(digest, v, r, s);

        require(recoveredAddress != address(0) && recoveredAddress == owner, 'Dynamic: INVALID_SIGNATURE');

        _approve(owner, spender, value);

    }

}


// File: bSwap-v2-core/contracts/DynamicVoting.sol

pragma solidity =0.5.16;






contract DynamicVoting is DynamicERC20 {

    uint256 public votingTime;   // duration of voting

    uint256 public minimalLevel; // user who has this percentage of token can suggest change

    

    uint256 public ballotIds;

    uint256 public rulesIds;

    

    enum Vote {None, Yea, Nay}

    enum Status {New , Executed}



    struct Rule {

        //address contr;      // contract address which have to be triggered

        uint32 majority;  // require more than this percentage of participants voting power (in according tokens).

        string funcAbi;     // function ABI (ex. "transfer(address,uint256)")

    }



    struct Ballot {

        uint256 closeVote; // timestamp when vote will close

        uint256 ruleId; // rule which edit

        bytes args; // ABI encoded arguments for proposal which is required to call appropriate function

        Status status;

        address creator;    // wallet address of ballot creator.

        uint256 yea;  // YEA votes according communities (tokens)

        uint256 totalVotes;  // The total voting power od all participant according communities (tokens)

    }

    

    mapping(address => mapping(uint256 => bool)) public voted;

    mapping(uint256 => Ballot) public ballots;

    mapping(uint256 => Rule) public rules;

    //event AddRule(address indexed contractAddress, string funcAbi, uint32 majorMain);

    event ApplyBallot(uint256 indexed ruleId, uint256 indexed ballotId);

    event BallotCreated(uint256 indexed ruleId, uint256 indexed ballotId);

    

    modifier onlyVoting() {

        require(address(this) == msg.sender, "Only voting");

        _;        

    }



    function initialize() internal {

        rules[0] = Rule(75,"setVotingDuration(uint256)");

        rules[1] = Rule(75,"setMinimalLevel(uint256)");

        rules[2] = Rule(75,"setVars(uint256,uint32)");

        rules[3] = Rule(75,"switchPool(uint256)");

        rulesIds = 3;

        votingTime = 1 days;

        minimalLevel = 10;

        super.initialize();

    }

    

    /**

     * @dev Add new rule - function that call target contract to change setting.

        * @param contr The contract address which have to be triggered

        * @param majority The majority level (%) for the tokens 

        * @param funcAbi The function ABI (ex. "transfer(address,uint256)")

     */

     /*

    function addRule(

        address contr,

        uint32  majority,

        string memory funcAbi

    ) external onlyOwner {

        require(contr != address(0), "Zero address");

        rulesIds +=1;

        rules[rulesIds] = Rule(contr, majority, funcAbi);

        emit AddRule(contr, funcAbi, majority);

    }

    */



    /**

     * @dev Set voting duration

     * @param time duration in seconds

    */

    function setVotingDuration(uint256 time) external onlyVoting {

        require(time > 600);

        votingTime = time;

    }

    

    /**

     * @dev Set minimal level to create proposal

     * @param level in percentage. I.e. 10 = 10%

    */

    function setMinimalLevel(uint256 level) external onlyVoting {

        require(level >= 1 && level <= 51);    // not less then 1% and not more then 51%

        minimalLevel = level;

    }

    

    /**

     * @dev Get rules details.

     * @param ruleId The rules index

     * @return contr The contract address

     * @return majority The level of majority in according tokens

     * @return funcAbi The function Abi (ex. "transfer(address,uint256)")

    */

    function getRule(uint256 ruleId) external view returns(uint32 majority, string memory funcAbi) {

        Rule storage r = rules[ruleId];

        return (r.majority, r.funcAbi);

    }

    

    function _checkMajority(uint32 majority, uint256 _ballotId) internal view returns(bool){

        Ballot storage b = ballots[_ballotId];

        if (b.yea * 2 > totalSupply) {

            return true;

        }

        if((b.totalVotes - b.yea) * 2 > totalSupply){

            return false;

        }

        if (block.timestamp >= b.closeVote && b.yea > b.totalVotes * majority / 100) {

            return true;

        }

        return false;

    }



    function vote(uint256 _ballotId, bool yea) external returns (bool){

        require(_ballotId <= ballotIds, "Wrong ballot ID");

        require(!voted[msg.sender][_ballotId], "already voted");

        

        Ballot storage b = ballots[_ballotId];

        uint256 closeVote = b.closeVote;

        require(closeVote > block.timestamp, "voting closed");

        uint256 power = balanceOf[msg.sender];

        

        if(yea){

            b.yea += power;    

        }

        b.totalVotes += power;

        voted[msg.sender][_ballotId] = true;

        if(_checkMajority(rules[b.ruleId].majority, _ballotId)) {

            _executeBallot(_ballotId);

        } else if (locked[msg.sender] < closeVote) {

            locked[msg.sender] = closeVote;

        }

        return true;

    }

    



    function createBallot(uint256 ruleId, bytes calldata args) external {

        require(ruleId <= rulesIds, "Wrong rule ID");

        Rule storage r = rules[ruleId];

        uint256 power = balanceOf[msg.sender];

        require(power >= totalSupply * minimalLevel / 100, "require minimal Level to suggest change");

        uint256 closeVote = block.timestamp + votingTime;

        ballotIds += 1;

        Ballot storage b = ballots[ballotIds];

        b.ruleId = ruleId;

        b.args = args;

        b.creator = msg.sender;

        b.yea = power;

        b.totalVotes = power;

        b.closeVote = closeVote;

        b.status = Status.New;

        voted[msg.sender][ballotIds] = true;

        emit BallotCreated(ruleId, ballotIds);

        

        if (_checkMajority(r.majority, ballotIds)) {

            _executeBallot(ballotIds);

        } else if (locked[msg.sender] < closeVote) {

            locked[msg.sender] = closeVote;

        }

    }

    

    function executeBallot(uint256 _ballotId) external {

        Ballot storage b = ballots[_ballotId];

        if(_checkMajority(rules[b.ruleId].majority, _ballotId)){

            _executeBallot(_ballotId);

        }

    }

    

    

    /**

     * @dev Apply changes from ballot.

     * @param ballotId The ballot index

     */

    function _executeBallot(uint256 ballotId) internal {

        Ballot storage b = ballots[ballotId];

        require(b.status != Status.Executed,"Ballot is Executed");

        Rule storage r = rules[b.ruleId];

        bytes memory command = abi.encodePacked(bytes4(keccak256(bytes(r.funcAbi))), b.args);

        trigger(address(this), command);

        b.closeVote = block.timestamp;

        b.status = Status.Executed;

        emit ApplyBallot(b.ruleId, ballotId);

    }



    

    /**

     * @dev Apply changes from Governance System. Call destination contract.

     * @param contr The contract address to call

     * @param params encoded params

     */

    function trigger(address contr, bytes memory params) internal  {

        (bool success,) = contr.call(params);

        require(success, "Trigger error");

    }

}
// File: bSwap-v2-core/contracts/interfaces/IDynamicPair.sol

pragma solidity >=0.5.0;



interface IDynamicPair {

    event Approval(address indexed owner, address indexed spender, uint value);

    event Transfer(address indexed from, address indexed to, uint value);



    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);



    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);



    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);



    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;



    event Mint(address indexed sender, uint amount0, uint amount1);

    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);

    event Swap(

        address indexed sender,

        uint amount0In,

        uint amount1In,

        uint amount0Out,

        uint amount1Out,

        address indexed to

    );

    event Sync(uint112 reserve0, uint112 reserve1);



    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);



    function vars(uint id) external view returns (uint32);

    function baseLinePrice0() external view returns (uint);

    function lastMA() external view returns (uint);

    function isPrivate() external view returns (uint8);



    function votingTime() external view returns (uint);

    function minimalLevel() external view returns (uint);



    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;



    function initialize(address, address, uint32[8] calldata, uint8) external;



    function addReward(uint amount) external;

    function getRewards(address user) external view returns (uint);

    function getAmountOut(uint amountIn, address tokenIn, address tokenOut) external view returns(uint);

    function getAmountIn(uint amountOut, address tokenIn, address tokenOut) external view returns(uint);

}


// File: bSwap-v2-core/contracts/DynamicPair.sol

pragma solidity =0.5.16;










// This contract is implementation of code for pair.

contract DynamicPair is IDynamicPair, DynamicVoting {

    using SafeMath  for uint;

    using UQ112x112 for uint224;

    

    enum Vars {timeFrame, maxDump0, maxDump1, maxTxDump0, maxTxDump1, coefficient, minimalFee, periodMA}

    uint32[8] public vars; // timeFrame, maxDump0, maxDump1, maxTxDump0, maxTxDump1, coefficient, minimalFee, periodM

    //timeFrame = 1 days;  // during this time frame rate of reserve1/reserve0 should be in range [baseLinePrice0*(1-maxDump0), baseLinePrice0*(1+maxDump1)]

    //maxDump0 = 10000;   // maximum allowed dump (in percentage with 2 decimals) of reserve1/reserve0 rate during time frame relatively the baseline

    //maxDump1 = 10000;   // maximum allowed dump (in percentage with 2 decimals) of reserve0/reserve1 rate during time frame relatively the baseline

    //maxTxDump0 = 10000; // maximum allowed dump (in percentage with 2 decimals) of token0 price per transaction

    //maxTxDump1 = 10000; // maximum allowed dump (in percentage with 2 decimals) of token1 price per transaction

    //coefficient = 10000; // coefficient (in percentage with 2 decimals) to transform price growing into fee. ie

    //minimalFee = 10;   // Minimal fee percentage (with 2 decimals) applied to transaction. I.e. 10 = 0.1%

    //periodMA = 45*60;  // MA period in seconds



    uint256 public baseLinePrice0;// base line of reserve1/reserve0 rate fixed on beginning od each time frame.

    uint256 public lastMA;        // last MA value



    uint public constant MINIMUM_LIQUIDITY = 10**3;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));



    address public factory;

    address public token0;

    address public token1;

    uint8 public isPrivate;  // in private pool only LP holder (creator) can add more liquidity



    uint112 private reserve0;           // uses single storage slot, accessible via getReserves

    uint112 private reserve1;           // uses single storage slot, accessible via getReserves

    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves



    uint public price0CumulativeLast;

    uint public price1CumulativeLast;

    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event



    uint private unlocked;

    modifier lock() {

        require(unlocked == 1, 'Dynamic: LOCKED');

        unlocked = 0;

        _;

        unlocked = 1;

    }



    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {

        _reserve0 = reserve0;

        _reserve1 = reserve1;

        _blockTimestampLast = blockTimestampLast;

    }



    function _safeTransfer(address token, address to, uint value) private {

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));

        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Dynamic: TRANSFER_FAILED');

    }



    event Mint(address indexed sender, uint amount0, uint amount1);

    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);

    event Swap(

        address indexed sender,

        uint amount0In,

        uint amount1In,

        uint amount0Out,

        uint amount1Out,

        address indexed to

    );

    event Sync(uint112 reserve0, uint112 reserve1);

    event AddReward(uint reward);



    /*

    constructor() public {

        factory = msg.sender;

    }

    */



    // called once by the factory at time of deployment

    function initialize(address _token0, address _token1, uint32[8] calldata _vars, uint8 _isPrivate) external {

        require(address(0) == factory, 'Dynamic: FORBIDDEN'); // sufficient check

        unlocked = 1;

        factory = msg.sender;

        token0 = _token0;

        token1 = _token1;

        vars = _vars;

        isPrivate = _isPrivate;

        super.initialize();

    }



    function getAmountOut(uint amountIn, address tokenIn, address tokenOut) external view returns(uint amountOut) {

        (amountOut,) = getAmountOutAndFee(amountIn, tokenIn, tokenOut);

    }



    function getAmountOutAndFee(uint amountIn, address tokenIn, address tokenOut) public view returns(uint amountOut, uint fee) {

        uint32[8] memory _vars = vars;

        uint ma;

        uint112 reserveIn = reserve0;

        uint112 reserveOut = reserve1;

        uint32 blockTimestamp = uint32(block.timestamp % 2**32);        

        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        uint priceBefore0 = uint(UQ112x112.encode(reserveOut).uqdiv(reserveIn));

        if (timeElapsed >= _vars[uint(Vars.periodMA)]) ma = priceBefore0;

        else ma = ((_vars[uint(Vars.periodMA)] - timeElapsed)*lastMA + priceBefore0*timeElapsed) / _vars[uint(Vars.periodMA)];

        uint k = uint(reserveIn) * reserveOut;

        if (tokenIn < tokenOut) {

            uint balance = reserveIn + amountIn;

            uint priceAfter0 = uint(UQ112x112.encode(uint112(k/balance)).uqdiv(uint112(balance)));

            fee = priceAfter0 * 10000 / ma;

        } else {

            uint balance = reserveOut + amountIn;

            uint priceAfter0 = uint(UQ112x112.encode(uint112(balance)).uqdiv(uint112(k/balance)));

            fee = ma * 10000 / priceAfter0;

            (reserveIn, reserveOut) = (reserveOut, reserveIn);

        }

        if (fee < 10000) {

            fee = (10000 - fee) * _vars[uint(Vars.coefficient)] / 10000;

            if (fee < _vars[uint(Vars.minimalFee)]) fee = _vars[uint(Vars.minimalFee)];

        } else {

            fee = _vars[uint(Vars.minimalFee)];

        }

        amountIn = amountIn * (10000 - fee);

        amountOut = reserveOut*amountIn / (reserveIn * 10000 + amountIn);

    }



    function getAmountIn(uint amountOut, address tokenIn, address tokenOut) external view returns(uint amountIn) {

        (amountIn,) = getAmountInAndFee(amountOut, tokenIn, tokenOut);

    }



    function getAmountInAndFee(uint amountOut, address tokenIn, address tokenOut) public view returns(uint amountIn, uint fee) {

        uint32[8] memory _vars = vars;

        uint ma;

        uint112 reserveIn = reserve0;

        uint112 reserveOut = reserve1;

        uint32 blockTimestamp = uint32(block.timestamp % 2**32);        

        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        uint priceBefore0 = uint(UQ112x112.encode(reserveOut).uqdiv(reserveIn));

        if (timeElapsed >= _vars[uint(Vars.periodMA)]) ma = priceBefore0;

        else ma = ((_vars[uint(Vars.periodMA)] - timeElapsed)*lastMA + priceBefore0*timeElapsed) / _vars[uint(Vars.periodMA)];

        uint k = uint(reserveIn) * reserveOut;

        if (tokenIn < tokenOut) {

            uint balance = reserveOut - amountOut;

            uint priceAfter0 = uint(UQ112x112.encode(uint112(balance)).uqdiv(uint112(k/balance)));

            fee = priceAfter0 * 10000 / ma;

        } else {

            uint balance = reserveIn - amountOut;

            uint priceAfter0 = uint(UQ112x112.encode(uint112(k/balance)).uqdiv(uint112(balance)));

            fee = ma * 10000 / priceAfter0;

            (reserveIn, reserveOut) = (reserveOut, reserveIn);

        }

        if (fee < 10000) {

            fee = (10000 - fee) * _vars[uint(Vars.coefficient)] / 10000;

            if (fee < _vars[uint(Vars.minimalFee)]) fee = _vars[uint(Vars.minimalFee)];

        } else {

            fee = _vars[uint(Vars.minimalFee)];

        }

        amountOut = amountOut * 10000 / (10000 - fee);

        amountIn = reserveIn*amountOut / (reserveOut - amountOut);

    }

    

    function _getFeeAndDumpProtection(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private returns(uint fee0, uint fee1){

        uint32 blockTimestamp = uint32(block.timestamp % 2**32);

        require(_reserve0 != 0, "_reserve0 = 0");

        require(_reserve1 != 0, "_reserve1 = 0");        

        require(balance0 != 0, "balance0 = 0");

        require(balance1 != 0, "balance1 = 0");

        uint priceBefore0 = uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0));

        uint priceAfter0 = uint(UQ112x112.encode(uint112(balance1)).uqdiv(uint112(balance0)));

        require(priceBefore0 != 0, "priceBefore0 = 0");

        require(priceAfter0 != 0, "priceAfter0 = 0");

        uint32[8] memory _vars = vars;

        {

        // check transaction dump range

        require(priceAfter0 * 10000 / priceBefore0 >= (uint(10000).sub(_vars[uint(Vars.maxTxDump0)])) &&

            priceBefore0 * 10000 / priceAfter0 >= (uint(10000).sub(_vars[uint(Vars.maxTxDump1)])),

            "Slippage out of allowed range"

        );

        // check time frame dump range

        uint _baseLinePrice0 = baseLinePrice0;

        if (blockTimestamp/_vars[uint(Vars.timeFrame)] != blockTimestampLast/_vars[uint(Vars.timeFrame)]) {   //new time frame 

            _baseLinePrice0 = uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0));

            baseLinePrice0 = _baseLinePrice0;

        }

        if (_baseLinePrice0 !=0)

            require(priceAfter0 * 10000 / _baseLinePrice0 >= (uint(10000).sub(_vars[uint(Vars.maxDump0)])) &&

                _baseLinePrice0 * 10000 / priceAfter0 >= (uint(10000).sub(_vars[uint(Vars.maxDump1)])),

                "Slippage out of time frame allowed range"

            );

        }

        {        

        // ma = ((periodMA - timeElapsed)*lastMA + lastPrice*timeElapsed) / periodMA

        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        uint ma;

        if (timeElapsed >= _vars[uint(Vars.periodMA)]) ma = priceBefore0;

        else ma = ((_vars[uint(Vars.periodMA)] - timeElapsed)*lastMA + priceBefore0*timeElapsed) / _vars[uint(Vars.periodMA)];

        lastMA = ma;

        fee0 = priceAfter0 * 10000 / ma;

        if (fee0 <= 10000) {

            fee0 = (10000 - fee0) * _vars[uint(Vars.coefficient)] / 10000;

            if (fee0 < _vars[uint(Vars.minimalFee)]) fee0 = _vars[uint(Vars.minimalFee)];

            fee1 = _vars[uint(Vars.minimalFee)];   // minimalFee when price drop

        } else {

            // fee1 = 10000*10000 / fee0

            fee1 = uint(10000).sub(100000000 / fee0) * _vars[uint(Vars.coefficient)] / 10000;

            if (fee1 < _vars[uint(Vars.minimalFee)]) fee1 = _vars[uint(Vars.minimalFee)];

            fee0 = _vars[uint(Vars.minimalFee)];   // minimalFee when price drop

        }

        }

    }



    // update reserves and, on the first call per block, price accumulators

    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {

        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'Dynamic: OVERFLOW');

        uint32 blockTimestamp = uint32(block.timestamp % 2**32);

        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {

            // * never overflows, and + overflow is desired

            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;

            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;

        }

        reserve0 = uint112(balance0);

        reserve1 = uint112(balance1);

        blockTimestampLast = blockTimestamp;

        emit Sync(reserve0, reserve1);

    }

/*

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)

    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {

        address feeTo = IDynamicFactory(factory).feeTo();

        feeOn = feeTo != address(0);

        uint _kLast = kLast; // gas savings

        if (feeOn) {

            if (_kLast != 0) {

                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));

                uint rootKLast = Math.sqrt(_kLast);

                if (rootK > rootKLast) {

                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));

                    uint denominator = rootK.mul(5).add(rootKLast);

                    uint liquidity = numerator / denominator;

                    if (liquidity > 0) _mint(feeTo, liquidity);

                }

            }

        } else if (_kLast != 0) {

            kLast = 0;

        }

    }

*/

    // this low-level function should be called from a contract which performs important safety checks

    function mint(address to) external lock returns (uint liquidity) {

        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings

        uint balance0 = IERC20(token0).balanceOf(address(this));

        uint balance1 = IERC20(token1).balanceOf(address(this));

        uint amount0 = balance0.sub(_reserve0);

        uint amount1 = balance1.sub(_reserve1);



        //bool feeOn = _mintFee(_reserve0, _reserve1);

        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee

        if (_totalSupply == 0) {

            uint priceBefore0 = uint(UQ112x112.encode(uint112(balance1)).uqdiv(uint112(balance0)));

            lastMA = priceBefore0;

            baseLinePrice0 = priceBefore0;

            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);

           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens

        } else {

            require(isPrivate != 1 || balanceOf[to] != 0, "Private pool");

            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);

        }

        require(liquidity > 0, 'Dynamic: INSUFFICIENT_LIQUIDITY_MINTED');

        _mint(to, liquidity);



        _update(balance0, balance1, _reserve0, _reserve1);

        //if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date

        emit Mint(msg.sender, amount0, amount1);

    }



    // this low-level function should be called from a contract which performs important safety checks

    function burn(address to) external lock returns (uint amount0, uint amount1) {

        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings

        address _token0 = token0;                                // gas savings

        address _token1 = token1;                                // gas savings

        uint balance0 = IERC20(_token0).balanceOf(address(this));

        uint balance1 = IERC20(_token1).balanceOf(address(this));

        uint liquidity = balanceOf[address(this)];



        //bool feeOn = _mintFee(_reserve0, _reserve1);

        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee

        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution

        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution

        require(amount0 > 0 && amount1 > 0, 'Dynamic: INSUFFICIENT_LIQUIDITY_BURNED');

        uint rewardAmount = _burn(address(this), liquidity);

        _safeTransfer(_token0, to, amount0);

        _safeTransfer(_token1, to, amount1);

        balance0 = IERC20(_token0).balanceOf(address(this));

        balance1 = IERC20(_token1).balanceOf(address(this));

        IDynamicFactory(factory).mintReward(to, rewardAmount);



        _update(balance0, balance1, _reserve0, _reserve1);

        //if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date

        emit Burn(msg.sender, amount0, amount1, to);

    }



    // this low-level function should be called from a contract which performs important safety checks

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {

        require(amount0Out > 0 || amount1Out > 0, 'Dynamic: INSUFFICIENT_OUTPUT_AMOUNT');

        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings

        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'Dynamic: INSUFFICIENT_LIQUIDITY');



        uint balance0;

        uint balance1;

        { // scope for _token{0,1}, avoids stack too deep errors

        address _token0 = token0;

        address _token1 = token1;

        require(to != _token0 && to != _token1, 'Dynamic: INVALID_TO');

        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens

        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens

        if (data.length > 0) IDynamicCallee(to).DynamicCall(msg.sender, amount0Out, amount1Out, data);

        balance0 = IERC20(_token0).balanceOf(address(this));

        balance1 = IERC20(_token1).balanceOf(address(this));

        }

        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;

        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;

        require(amount0In > 0 || amount1In > 0, 'Dynamic: INSUFFICIENT_INPUT_AMOUNT');

        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors

        uint fee0;

        uint fee1;

        address _token0 = token0;

        address _token1 = token1;

        if (to != factory) {    // avoid endless loop of fee swapping

            (fee0, fee1) = _getFeeAndDumpProtection(balance0, balance1, _reserve0, _reserve1);

            fee0 = amount0In.mul(fee0) / 10000;

            fee1 = amount1In.mul(fee1) / 10000;

            if (fee0 > 0) IERC20(_token0).approve(factory, fee0);

            if (fee1 > 0) IERC20(_token1).approve(factory, fee1);

            IDynamicFactory(factory).swapFee(_token0, _token1, fee0, fee1);

        }

        //uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));

        //uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));

        require((balance0.sub(fee0)).mul(balance1.sub(fee1)) >= uint(_reserve0).mul(_reserve1), 'Dynamic: K');

        //_update(IERC20(_token0).balanceOf(address(this)), IERC20(_token1).balanceOf(address(this)), _reserve0, _reserve1);

        }

        _update(balance0, balance1, _reserve0, _reserve1);

        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);

    }



    // force balances to match reserves

    function skim(address to) external lock {

        address _token0 = token0; // gas savings

        address _token1 = token1; // gas savings

        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));

        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));

    }



    // force reserves to match balances

    function sync() external lock {

        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);

    }



    // add reward tokens into the reward pool (only by factory)

    function addReward(uint amount) external {

        require(msg.sender == factory, "Only factory");

        rewardTokens = rewardTokens.add(amount);

        emit AddReward(amount);

    }



    function setVars(uint varId, uint32 value) external onlyVoting {

        require(varId < vars.length, "Wrong varID");

        if (varId == uint(Vars.timeFrame) || varId == uint(Vars.periodMA))

            require(value != 0, "Wrong time frame");

        else

            require(value <= 10000, "Wrong percentage");

        vars[varId] = value;

    }



    // private/public pool switching (just for pools )

    function switchPool(uint toPublic) external onlyVoting {

        require(isPrivate != 0, "Pool can't be switched");

        if(toPublic == 1 && isPrivate == 1) isPrivate = 2;  // switch pool to public mode (anybody can add liquidity)

        if(toPublic == 0 && isPrivate == 2) isPrivate = 1;  // switch pool to private mode (nobody, except LP holders, can add liquidity)

    }

}