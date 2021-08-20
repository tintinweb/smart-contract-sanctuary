/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @title TokenConverter
 * @author kotsmile
 */

interface ITokenConverter {

    /**
     * @dev Adds new pair if such doesnt exist
     * @param _token0Address first token address  
     * @param _token1Address second token address
     *      
     *  Emits a {PairAdded} event
     */
    function addPair(address _token0Address, address _token1Address) external;

    /**
     * @dev Returns existing of provided pair
     * @param _token0Symbol first token symbol  
     * @param _token1Symbol second token symbol
     * @return _existing existing of current pair  
     */ 
    function isPairExists(string memory _token0Symbol, string memory _token1Symbol) external view returns (bool _existing);

    /**
     * @dev Returns existing of provided pair
     * @param _token0Address first token address  
     * @param _token1Address second token address
     * @return _existing existing of current pair  
     */ 
    function isPairExists(address _token0Address, address _token1Address) external view returns (bool _existing);

    /**
     * @dev Checks for pair existing. If pair doesnt exist adds it
     * @param _token0Address first token address  
     * @param _token1Address second token address
     */
    function requirePair(address _token0Address, address _token1Address) external;

    /**
     * @dev Returns reserves from liquadity pools on Uniswap
     * @param _token0Symbol first token symbol  
     * @param _token1Symbol second token symbol
     * @return _token0Reserve first token reserve  
     * @return _token1Reserve second token reserve
     */ 
    function getReserves(string memory _token0Symbol, string memory _token1Symbol) external view returns (uint112 _token0Reserve, uint112 _token1Reserve);

    /**
     * @dev Converts one token to another. Requares symbols
     * @param _amountInTokenFrom amount of from token
     * @param _tokenFromSymbol from token symbol  
     * @param _tokenToSymbol to token symbol
     * @return _amountInTokenTo amount of to token
     */ 
    function convert(uint256 _amountInTokenFrom, string memory _tokenFromSymbol, string memory _tokenToSymbol) external view returns (uint256 _amountInTokenTo); 

    /**
     * @dev Converts one token to another. Requares symbols
     * @param _amountInTokenFrom amount of from token
     * @param _tokenFromAddress from token address  
     * @param _tokenToAddress to token address
     * @return _amountInTokenTo amount of to token
     */ 
    function convert(uint256 _amountInTokenFrom, address _tokenFromAddress, address _tokenToAddress) external view returns (uint256 _amountInTokenTo);
    
    event PairAdded(address indexed sender, address indexed tokenFromAddress, address indexed tokenToAddress);
}

interface IERC20 {
    function symbol() external view returns (string memory);
}

interface IDEXRouter {
    function factory() external pure returns (address);
}

interface IDEXFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapPair {
    function token0() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract TokenConverter is ITokenConverter {
    struct Pair {
        address from;
        address to;
        address uniswapPairAddress;
    }
    mapping(string => mapping(string => Pair)) pairs;
    
    address public constant ROUTER = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    
    IDEXRouter public router;
    IDEXFactory public factory;

    constructor() {
        router = IDEXRouter(ROUTER);
        factory = IDEXFactory(router.factory());
    }

    function addPair(address _token0Address, address _token1Address) 
    public 
    override {
        require(_token0Address != address(0) && _token1Address != address(0), '[TokenConverter]: Cant add pair from or to address 0x0');

        string memory _token0Symbol = IERC20(_token0Address).symbol();
        string memory _token1Symbol = IERC20(_token1Address).symbol();

        require(!isPairExists(_token0Symbol, _token1Symbol), '[TokenConverter]: Cant add already existed pair');

        address _pairAddress = factory.getPair(_token0Address, _token1Address);
        if (_pairAddress == address(0)) {
            _pairAddress = factory.createPair(_token0Address, _token1Address);
        }

        Pair memory newPair0 = Pair({
            from: _token0Address,
            to: _token1Address,
            uniswapPairAddress: _pairAddress
        });

        Pair memory newPair1 = Pair({
            from: _token1Address,
            to: _token0Address,
            uniswapPairAddress: _pairAddress
        });

        pairs[_token0Symbol][_token1Symbol] = newPair0;
        pairs[_token1Symbol][_token0Symbol] = newPair1;

        emit PairAdded(msg.sender, _token0Address, _token1Address);

    }

    function isPairExists(string memory _token0Symbol, string memory _token1Symbol)
    public 
    view
    override
    returns (bool _existing) {
        return pairs[_token0Symbol][_token1Symbol].from != address(0) && 
               pairs[_token0Symbol][_token1Symbol].to != address(0) &&
               pairs[_token0Symbol][_token1Symbol].uniswapPairAddress != address(0);
    }

    function isPairExists(address _token0Address, address _token1Address)
    public 
    view
    override
    returns (bool _existing) {

        string memory _token0Symbol = IERC20(_token0Address).symbol();
        string memory _token1Symbol = IERC20(_token1Address).symbol();

        return isPairExists(_token0Symbol, _token1Symbol);
    }
    
    function requirePair(address _token0Address, address _token1Address)
    public
    override {
        require(_token0Address != address(0) && _token1Address != address(0), '[TokenConverter]: Cant require pair from or to address 0x0');
        if (!isPairExists(_token0Address, _token1Address)) {
            addPair(_token0Address, _token1Address);
        }

    }

    function getReserves(string memory _token0Symbol, string memory _token1Symbol)
    public
    view
    override
    returns (uint112 _token0Reserve, uint112 _token1Reserve) {
        IUniswapPair uniswapPair =  IUniswapPair(pairs[_token0Symbol][_token1Symbol].uniswapPairAddress);
        address _token0Address = pairs[_token0Symbol][_token1Symbol].from;
        (uint112 _reserve0, uint112 _reserve1,) = uniswapPair.getReserves();

        if (_reserve0 + _reserve1 == 0) return (1, 1);

        if (uniswapPair.token0() == _token0Address) {
            return (_reserve0, _reserve1);
        }
        return (_reserve0, _reserve1);
    }

    function convert(uint256 _amountInTokenFrom, string memory _tokenFromSymbol, string memory _tokenToSymbol)
    public
    view 
    override
    returns (uint256 _amountInTokenTo) {
        require(isPairExists(_tokenFromSymbol, _tokenToSymbol), '[TokenConverter]: Cant convert this pair');
        (uint112 _tokenFromReserve, uint112 _tokenToResrve) = getReserves(_tokenFromSymbol, _tokenToSymbol);
        
        return (_amountInTokenFrom * _tokenToResrve) / _tokenFromReserve;
    }

    function convert(uint256 _amountInTokenFrom, address _tokenFromAddress, address _tokenToAddress)
    public
    view 
    override
    returns (uint256 _amountInTokenTo) {
        require(_tokenFromAddress != address(0) && _tokenToAddress != address(0), '[TokenConverter]: Cant add pair from or to address 0x0');
        string memory _tokenFromSymbol = IERC20(_tokenFromAddress).symbol();
        string memory _tokenToSymbol = IERC20(_tokenToAddress).symbol();

        return convert(_amountInTokenFrom, _tokenFromSymbol, _tokenToSymbol);
    }

}