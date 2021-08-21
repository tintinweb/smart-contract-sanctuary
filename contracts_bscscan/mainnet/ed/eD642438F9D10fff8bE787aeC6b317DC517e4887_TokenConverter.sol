/**
 *Submitted for verification at BscScan.com on 2021-08-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @title TokenConverter
 * @author kotsmile
 */

interface ITokenConverter {

    /**
     * @dev Adds new pair if such does not exist
     * @param _token0 first token address  
     * @param _token1 second token address
     *      
     *  Emits a {PairAdded} event
     */
    function addPair(address _token0, address _token1) external;

    /**
     * @dev Sorts in ascending order
     * @param _token0 first token address  
     * @param _token1 second token address
     * @return token0 smaller one  
     * @return token1 larger one
     */ 
    function order(address _token0, address _token1) external pure returns (address token0, address token1);

    /**
     * @dev Returns existing of provided pair
     * @param _token0 first token address  
     * @param _token1 second token address
     * @return _existing existing of current pair  
     */ 
    function isPairExists(address _token0, address _token1) external view returns (bool _existing);

    /**
     * @dev Checks for pair existing. If pair does not exist adds it
     * @param _token0 first token address  
     * @param _token1 second token address
     */
    function requirePair(address _token0, address _token1) external;

    /**
     * @dev Returns reserves from liquadity pools on Uniswap
     * @param _token0 first token address  
     * @param _token1 second token address
     * @return _token0Reserve first token reserve  
     * @return _token1Reserve second token reserve
     */ 
    function getReserves(address _token0, address _token1) external view returns (uint112 _token0Reserve, uint112 _token1Reserve);

    /**
     * @dev Returns Uniswap Pair address of contract
     * @param _token0 first token address  
     * @param _token1 second token address
     * @return _pair Uniswap Pair address of contract 
     */ 
    function getPair(address _token0, address _token1) external view returns (address _pair);

    /**
     * @dev Converts one token to another. Requares symbols
     * @param _amountInTokenFrom amount of from token
     * @param _tokenFrom from token address  
     * @param _tokenTo to token address
     * @return _amountInTokenTo amount of to token
     */ 
    function convert(uint256 _amountInTokenFrom, address _tokenFrom, address _tokenTo) external view returns (uint256 _amountInTokenTo);
    
    event PairAdded(
        address indexed sender,
        address tokenFromAddress, 
        address tokenToAddress, 
        address uniswapPair
    );
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

    mapping(address => mapping(address => address)) pairs;

    address public constant ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    IDEXRouter public router;
    IDEXFactory public factory;

    constructor() {
        router = IDEXRouter(ROUTER);
        factory = IDEXFactory(router.factory());
    }

    function addPair(address _token0, address _token1) 
    public
    override {
        require(_token0 != address(0), '[TokenConverter]: _token0 cannot be address 0x0');
        require(_token1 != address(0), '[TokenConverter]: _token1 cannot be address 0x0');
        if (_token0 == _token1) return;
        require(!isPairExists(_token0, _token1), '[TokenConverter]: Cant add already existed pair');

        address _pair = factory.getPair(_token0, _token1);
        if (_pair == address(0)) {
            _pair = factory.createPair(_token0, _token1);
        }

        (_token0, _token1) = order(_token0, _token1);
        pairs[_token0][_token1] = _pair;

        emit PairAdded(msg.sender, _token0, _token1, _pair);
    }    

    function order(address _token0, address _token1)
    public
    override
    pure
    returns (address token0, address token1) {
        return _token0 < _token1 ? (_token0, _token1) : (_token1, _token0);
    }

    function isPairExists(address _token0, address _token1)
    public
    override 
    view
    returns (bool _existing) {
        (_token0, _token1) = order(_token0, _token1);
        if (_token0 == _token1) return true;
        return pairs[_token0][_token1] != address(0);
    }

    
    function requirePair(address _token0, address _token1)
    public
    override {
        require(_token0 != address(0) && _token1 != address(0), '[TokenConverter]: Cant require pair from or to address 0x0');
        if (_token0 == _token1) return; 
        if (!isPairExists(_token0, _token1)) {
            addPair(_token0, _token1);
        }
    }

    function getReserves(address _token0, address _token1)
    public
    override
    view
    returns (uint112 _token0Reserve, uint112 _token1Reserve) {
        require(_token0 != address(0) && _token1 != address(0), '[TokenConverter]: Cant convert pair from or to address 0x0');
        if (_token0 == _token1) return (1, 1);

        IUniswapPair uniswapPair = IUniswapPair(getPair(_token0, _token1));
        
        (uint112 _reserve0, uint112 _reserve1,) = uniswapPair.getReserves();

        if (_reserve0 + _reserve1 == 0) return (1, 1);
        return uniswapPair.token0() == _token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);

    }

    function getPair(address _token0, address _token1)
    public
    override
    view
    returns (address _pair) {
        (_token0, _token1) = order(_token0, _token1); 
        return pairs[_token0][_token1];
    }


    function convert(uint256 _amountInTokenFrom, address _tokenFrom, address _tokenTo)
    public
    override
    view 
    returns (uint256 _amountInTokenTo) {
        require(_tokenFrom != address(0) && _tokenTo != address(0), '[TokenConverter]: Cant convert pair from or to address 0x0');
        if (_tokenFrom == _tokenTo) return _amountInTokenFrom;

        require(isPairExists(_tokenFrom, _tokenTo), '[TokenConverter]: Cant convert this pair');

        (uint112 _tokenFromReserve, uint112 _tokenToReserve) = getReserves(_tokenFrom, _tokenTo);
        return (_amountInTokenFrom * _tokenToReserve) / _tokenFromReserve;
    }

}