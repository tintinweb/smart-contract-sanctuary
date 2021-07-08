/**
 *Submitted for verification at polygonscan.com on 2021-07-08
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
    * onlyOwner functions anymore. Can only be called by the current owner.
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

interface IOraiBase {
    struct ResponsePriceData {
        uint128 rate; // base/quote exchange rate, multiplied by 1e18.
        uint64 lastUpdatedBase;
        uint64 lastUpdatedQuote; // UNIX epoch of the last time when quote price gets updated.
    }

    struct PriceData {
        uint128 rate; // USD-rate, multiplied by 1e18.
        uint64 resolveTime; // UNIX epoch when data is last resolved.
    }

    function getPrice(string memory _base, string memory _quote)
    external
    view
    returns (ResponsePriceData memory);

    function getPrice(string memory _base)
    external
    view
    returns (PriceData memory);

    function getPriceBulk(string[] memory _bases)
    external
    view
    returns (PriceData[] memory);

    function getPriceBulk(string[] memory _bases, string[] memory _quotes)
    external
    view
    returns (ResponsePriceData[] memory);


}

abstract contract OraiBase is IOraiBase {

    function getPrice(string memory _base, string memory _quote)
    public
    virtual
    override
    view
    returns (ResponsePriceData memory);

    function getPrice(string memory _base)
    public
    virtual
    override
    view
    returns (PriceData memory);

    function getPriceBulk(string[] memory _bases)
    public
    override
    view
    returns (PriceData[] memory)
    {
        uint256 len = _bases.length;
        PriceData[] memory results = new PriceData[](len);
        for (uint256 idx = 0; idx < len; idx++) {
            results[idx] = getPrice(_bases[idx]);
        }
        return results;
    }

    function getPriceBulk(string[] memory _bases, string[] memory _quotes)
    public
    override
    view
    returns (ResponsePriceData[] memory)
    {
        require(_bases.length == _quotes.length, "BAD_INPUT_LENGTH");
        uint256 len = _bases.length;
        ResponsePriceData[] memory results = new ResponsePriceData[](len);
        for (uint256 idx = 0; idx < len; idx++) {
            results[idx] = getPrice(_bases[idx], _quotes[idx]);
        }
        return results;
    }
}

contract OraiOraclePriceDataProxy is Ownable, OraiBase {
    IOraiBase public oracle;

    constructor(IOraiBase _oracle) public {
        oracle = _oracle;
    }

    function setOracle(IOraiBase _oracle) public onlyOwner {
        oracle = _oracle;
    }

    function getPrice(string memory _base, string memory _quote)
    public
    override
    view
    returns (ResponsePriceData memory)
    {
        return oracle.getPrice(_base, _quote);
    }
    function getPrice(string memory _base)
    public
    override
    view
    returns (PriceData memory)
    {
        return oracle.getPrice(_base);
    }

}