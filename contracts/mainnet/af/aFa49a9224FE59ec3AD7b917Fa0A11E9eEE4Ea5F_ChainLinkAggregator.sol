/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

pragma solidity 0.5.14;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy);
}


/**
 */
contract ChainLinkAggregator is Ownable{

    // TokenRegistry public import "../config/GlobalConfig.sol";;
    address public globalConfig;

    /**
     * Constructor
     */
    // constructor(TokenRegistry _tokenRegistry) public {
    //     require(address(_tokenRegistry) != address(0), "TokenRegistry address is zero");
    //     tokenRegistry = _tokenRegistry;
    // }

    /**
     *  initializes the symbols structure
     */
    function initialize(address _globalConfig) public onlyOwner{
        globalConfig = _globalConfig;
    }

    /**
     * Get latest update from the aggregator
     * @param _token token address
     */
    function getLatestAnswer(address _token) public view returns (int256) {
        return getAggregator(_token).latestAnswer();
    }

    /**
     * Get the timestamp of the latest update
     * @param _token token address
     */
    function getLatestTimestamp(address _token) public view returns (uint256) {
        return getAggregator(_token).latestTimestamp();
    }

    /**
     * Get the previous update
     * @param _token token address
     * @param _back the position of the answer if counting back from the latest
     */
    function getPreviousAnswer(address _token, uint256 _back) public view returns (int256) {
        AggregatorInterface aggregator = getAggregator(_token);
        uint256 latest = aggregator.latestRound();
        require(_back <= latest, "Not enough history");
        return aggregator.getAnswer(latest - _back);
    }

    /**
     * Get the timestamp of the previous update
     * @param _token token address
     * @param _back the position of the answer if counting back from the latest
     */
    function getPreviousTimestamp(address _token, uint256 _back) public view returns (uint256) {
        AggregatorInterface aggregator = getAggregator(_token);
        uint256 latest = aggregator.latestRound();
        require(_back <= latest, "Not enough history");
        return aggregator.getTimestamp(latest - _back);
    }

    /**
     * Get the aggregator address
     * @param _token token address
     */
    function getAggregator(address _token) internal view returns (AggregatorInterface) {
        // return AggregatorInterface(tokenRegistry.getChainLinkAggregator(_token));
        return AggregatorInterface(ITokenInfoRegistry(IGlobalConfig(globalConfig).tokenInfoRegistry()).getChainLinkAggregator(_token));
    }
}

interface IGlobalConfig {
    function tokenInfoRegistry() external view returns(address);
}

interface ITokenInfoRegistry {
    function getChainLinkAggregator(address _token) external view returns (address);
}