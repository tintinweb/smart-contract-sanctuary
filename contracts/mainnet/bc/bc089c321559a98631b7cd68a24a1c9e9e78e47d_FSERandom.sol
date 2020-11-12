pragma solidity ^0.5.0;

contract Context {
    constructor () internal {}
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}

pragma solidity ^0.5.0;

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


pragma solidity =0.5.16;

interface IUniswapV2Factory {
    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);
}


pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    function totalSupply() external view returns (uint);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);
}

pragma solidity ^0.5.0;

contract FSERandom is Ownable {
    mapping(address => bool) private _modules;
    IUniswapV2Factory private _uniswapV2Factory;
    address[] private _uniswapPools;
    bytes32 private _randNumber;

    modifier onlyModule() {
        require(_modules[_msgSender()], "Illegal caller!");
        _;
    }

    constructor (address __uniswapV2Factory, address[] memory __uniswapPools)
    public {
        _genRandomNumber(gasleft());
        setUniswapV2Factory(__uniswapV2Factory);
        setUniswapPools(__uniswapPools);
    }

    function setUniswapV2Factory(address __uniswapV2Factory)
    public onlyOwner {
        _uniswapV2Factory = IUniswapV2Factory(__uniswapV2Factory);
    }

    function setUniswapPools(address[] memory __uniswapPools)
    public onlyOwner {
        _uniswapPools = __uniswapPools;
    }

    function setModule(address _moduleAddress, bool _running)
    public onlyOwner {
        _modules[_moduleAddress] = _running;
    }

    function _genRandomNumber(uint256 _seed)
    internal
    returns (bytes32 _rand){
        _randNumber = keccak256(
            abi.encodePacked(
                _randNumber,
                _seed,
                gasleft(),
                block.number,
                blockhash(block.number - 1),
                block.coinbase,
                block.difficulty,
                block.gaslimit,
                block.timestamp));
        return _randNumber;
    }

    function _genRandByUniswapV2Pair(address _uniswapV2Pair)
    internal
    returns (bytes32 _rand){
        IUniswapV2Pair uniswapV2Pair = IUniswapV2Pair(_uniswapV2Pair);
        (uint256 reserve0, uint256 reserve1, uint256 blockTimestampLast) = uniswapV2Pair.getReserves();
        uint256 totalSupply = uniswapV2Pair.totalSupply();
        uint256 price0CumulativeLast = uniswapV2Pair.price0CumulativeLast();
        uint256 price1CumulativeLast = uniswapV2Pair.price1CumulativeLast();
        uint256 kLast = uniswapV2Pair.kLast();
        return _genRandomNumber(uint256(keccak256(abi.encodePacked(
                _uniswapV2Pair,
                reserve0,
                reserve1,
                blockTimestampLast,
                totalSupply,
                price0CumulativeLast,
                price1CumulativeLast,
                kLast))));
    }

    function genRandom(uint256 seed)
    public onlyModule
    returns (bytes32 _rand){
        require(_uniswapPools.length > 3, "Not enought pool size!");
        require(_uniswapV2Factory.allPairsLength() > 3, "Not enought pool size!");
        uint256 randTimes = uint256(_genRandomNumber(gasleft())) % 3 + 1;
        uint256 memPoolSize = _uniswapPools.length;
        uint256 randPos;
        for (uint i = 0; i < randTimes; i++) {
            randPos = uint256(_genRandomNumber(gasleft() + i)) % memPoolSize;
            _genRandByUniswapV2Pair(_uniswapPools[randPos]);
        }
        randTimes = uint256(_genRandomNumber(gasleft())) % 3 + 1;
        memPoolSize = _uniswapV2Factory.allPairsLength();
        for (uint i = 0; i < randTimes; i++) {
            randPos = uint256(_genRandomNumber(gasleft() + i)) % memPoolSize;
            _genRandByUniswapV2Pair(_uniswapV2Factory.allPairs(randPos));
        }
        return keccak256(abi.encodePacked(_randNumber, gasleft(), seed));
    }
}