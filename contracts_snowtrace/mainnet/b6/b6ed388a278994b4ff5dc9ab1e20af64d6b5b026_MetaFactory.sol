/**
 *Submitted for verification at snowtrace.io on 2021-12-26
*/

pragma solidity =0.6.12;

interface IFeeGetter{
    function getPairFee(address _tokenA, address _tokenB) external view returns(uint fee_);
    function dividendsDenominator() external view returns(uint);
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract MetaFactory is IUniswapV2Factory, Ownable{
    IUniswapV2Factory public factory;

    mapping(address=>address) public bank;

    mapping(address=>address) public underlying;

    function actualToken(address _token) view public returns(address actualToken_){
        actualToken_ = bank[_token] == address(0) ? _token : bank[_token];
    }

    function haveBank(address _token) view public returns(bool haveBank_){
        haveBank_ = bank[_token] != address(0);
    }

    function setBank(address _token, address _bank) public onlyOwner{
        bank[_token] = _bank;
        underlying[_bank] = _token;
    }

    constructor(address _factory) public{
        factory = IUniswapV2Factory(_factory);
    }

    function feeTo() external view override returns (address){
        return factory.feeTo();
    }

    function feeToSetter() external view override returns (address){
        return factory.feeToSetter();
    }

    function getPair(address tokenA, address tokenB) external view override returns (address pair){
        return factory.getPair(actualToken(tokenA), actualToken(tokenB));
    }

    function allPairs(uint i) external view override returns (address pair){
        return factory.allPairs(i);
    }

    function allPairsLength() external view override returns (uint){
        return factory.allPairsLength();
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair){
        return factory.createPair(actualToken(tokenA), actualToken(tokenB));
    }

    function setFeeTo(address) external override {
        revert("incorrect contract");
    }

    function setFeeToSetter(address) external override{
        revert("incorrect contract");
    }
}