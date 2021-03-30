/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IKeep3rV1 {
    function keepers(address keeper) external returns (bool);
    function KPRH() external view returns (IKeep3rV1Helper);
    function receipt(address credit, address keeper, uint amount) external;
}

interface IKeep3rV1Helper {
    function getQuoteLimit(uint gasUsed) external view returns (uint);
}

// sliding oracle that uses observations collected to provide moving price averages in the past
contract Keep3rV2Oracle {

    constructor(address _pair) {
        _factory = msg.sender;
        pair = _pair;
        (,,uint32 timestamp) = IUniswapV2Pair(_pair).getReserves();
        uint112 _price0CumulativeLast = uint112(IUniswapV2Pair(_pair).price0CumulativeLast() * e10 / Q112);
        uint112 _price1CumulativeLast = uint112(IUniswapV2Pair(_pair).price1CumulativeLast() * e10 / Q112);
        observations[length++] = Observation(timestamp, _price0CumulativeLast, _price1CumulativeLast);
    }

    struct Observation {
        uint32 timestamp;
        uint112 price0Cumulative;
        uint112 price1Cumulative;
    }

    modifier factory() {
        require(msg.sender == _factory, "!F");
        _;
    }

    Observation[65535] public observations;
    uint16 public length;

    address immutable _factory;
    address immutable public pair;
    // this is redundant with granularity and windowSize, but stored for gas savings & informational purposes.
    uint constant periodSize = 1800;
    uint Q112 = 2**112;
    uint e10 = 10**18;

    // Pre-cache slots for cheaper oracle writes
    function cache(uint size) external {
        uint _length = length+size;
        for (uint i = length; i < _length; i++) observations[i].timestamp = 1;
    }

    // update the current feed for free
    function update() external factory returns (bool) {
        return _update();
    }

    function updateable() external view returns (bool) {
        Observation memory _point = observations[length-1];
        (,, uint timestamp) = IUniswapV2Pair(pair).getReserves();
        uint timeElapsed = timestamp - _point.timestamp;
        return timeElapsed > periodSize;
    }

    function _update() internal returns (bool) {
        Observation memory _point = observations[length-1];
        (,, uint32 timestamp) = IUniswapV2Pair(pair).getReserves();
        uint32 timeElapsed = timestamp - _point.timestamp;
        if (timeElapsed > periodSize) {
            uint112 _price0CumulativeLast = uint112(IUniswapV2Pair(pair).price0CumulativeLast() * e10 / Q112);
            uint112 _price1CumulativeLast = uint112(IUniswapV2Pair(pair).price1CumulativeLast() * e10 / Q112);
            observations[length++] = Observation(timestamp, _price0CumulativeLast, _price1CumulativeLast);
            return true;
        }
        return false;
    }
}

contract Keep3rV2OracleFactory {

    function pairForSushi(address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
                hex'ff',
                0xc35DADB65012eC5796536bD9864eD8773aBc74C4,
                keccak256(abi.encodePacked(token0, token1)),
                hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303' // init code hash
            )))));
    }

    function pairForUni(address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
                hex'ff',
                0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            )))));
    }

    modifier keeper() {
        require(KP3R.keepers(msg.sender), "!K");
        _;
    }

    modifier upkeep() {
        uint _gasUsed = gasleft();
        require(KP3R.keepers(msg.sender), "!K");
        _;
        uint _received = KP3R.KPRH().getQuoteLimit(_gasUsed - gasleft());
        KP3R.receipt(address(KP3R), msg.sender, _received);
    }

    address public governance;
    address public pendingGovernance;

    /**
     * @notice Allows governance to change governance (for future upgradability)
     * @param _governance new governance address to set
     */
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!G");
        pendingGovernance = _governance;
    }

    /**
     * @notice Allows pendingGovernance to accept their role as governance (protection pattern)
     */
    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "!pG");
        governance = pendingGovernance;
    }

    IKeep3rV1 public constant KP3R = IKeep3rV1(0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44);

    address[] internal _pairs;
    mapping(address => Keep3rV2Oracle) public feeds;

    function pairs() external view returns (address[] memory) {
        return _pairs;
    }

    constructor() {
        governance = msg.sender;
    }

    function update(address pair) external keeper returns (bool) {
        return feeds[pair].update();
    }

    function byteCode(address pair) external pure returns (bytes memory bytecode) {
        bytecode = abi.encodePacked(type(Keep3rV2Oracle).creationCode, abi.encode(pair));
    }

    function deploy(address pair) external returns (address feed) {
        require(msg.sender == governance, "!G");
        require(address(feeds[pair]) == address(0), 'PE');
        bytes memory bytecode = abi.encodePacked(type(Keep3rV2Oracle).creationCode, abi.encode(pair));
        bytes32 salt = keccak256(abi.encodePacked(pair));
        assembly {
            feed := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(feed)) {
                revert(0, 0)
            }
        }
        feeds[pair] = Keep3rV2Oracle(feed);
        _pairs.push(pair);
    }

    function work() external upkeep {
        require(workable(), "!W");
        for (uint i = 0; i < _pairs.length; i++) {
            feeds[_pairs[i]].update();
        }
    }

    function work(address pair) external upkeep {
        require(feeds[pair].update(), "!W");
    }

    function workForFree() external keeper {
        for (uint i = 0; i < _pairs.length; i++) {
            feeds[_pairs[i]].update();
        }
    }

    function workForFree(address pair) external keeper {
        feeds[pair].update();
    }

    function cache(uint size) external {
        for (uint i = 0; i < _pairs.length; i++) {
            feeds[_pairs[i]].cache(size);
        }
    }

    function cache(address pair, uint size) external {
        feeds[pair].cache(size);
    }

    function workable() public view returns (bool canWork) {
        canWork = true;
        for (uint i = 0; i < _pairs.length; i++) {
            if (!feeds[_pairs[i]].updateable()) {
                canWork = false;
            }
        }
    }

    function workable(address pair) public view returns (bool) {
        return feeds[pair].updateable();
    }
}