/**
 *Submitted for verification at polygonscan.com on 2021-08-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;


interface IToken {
    function decimals() external view returns (uint8);
}


interface IOracleUsd {

    function assetToUsd(address asset, uint amount) external view returns (uint);
}



interface IAggregator {
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
    function latestRound() external view returns (uint256);
    function getAnswer(uint256 roundId) external view returns (int256);
    function getTimestamp(uint256 roundId) external view returns (uint256);
    function decimals() external view returns (uint256);

    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
    event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}




library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


abstract contract Ownable{
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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



/**
 * @title ChainlinkedOracleMainAsset
 * @dev Calculates the USD price of desired tokens
 **/
contract ChainlinkedOracleMainAsset is IOracleUsd, Ownable {
    using SafeMath for uint;

    mapping (address => address) public usdAggregators;

    uint public constant USD_TYPE = 0;

    event NewAggregator(address indexed asset, address indexed aggregator, uint aggType);

    constructor(
        address[] memory tokenAddresses1,
        address[] memory _usdAggregators
    )
        public
    {
        require(tokenAddresses1.length == _usdAggregators.length, "Voodoo Finance: ARGUMENTS_LENGTH_MISMATCH");

        for (uint i = 0; i < tokenAddresses1.length; i++) {
            usdAggregators[tokenAddresses1[i]] = _usdAggregators[i];
            emit NewAggregator(tokenAddresses1[i], _usdAggregators[i], USD_TYPE);
        }

    }

    function setAggregators(
        address[] calldata tokenAddresses1,
        address[] calldata _usdAggregators
    ) external onlyOwner {
        require(tokenAddresses1.length == _usdAggregators.length, "Voodoo Finance: ARGUMENTS_LENGTH_MISMATCH");

        for (uint i = 0; i < tokenAddresses1.length; i++) {
            usdAggregators[tokenAddresses1[i]] = _usdAggregators[i];
            emit NewAggregator(tokenAddresses1[i], _usdAggregators[i], USD_TYPE);
        }
    }

    /**
     * @notice {asset}/USD pair must be registered at Chainlink
     * @param asset The token address
     * @param amount Amount of tokens
     * @return price of asset amount in USD
     **/
    function assetToUsd(address asset, uint amount) public override view returns (uint) {
        if (amount == 0) {
            return 0;
        }
        require(usdAggregators[asset] != address(0), "Voodoo Finance: AGGREGATOR_DOES_NOT_EXIST");
    
        return _assetToUsd(asset, amount);
    }

    function _assetToUsd(address asset, uint amount) internal view returns (uint) {
        IAggregator agg = IAggregator(usdAggregators[asset]);
        (, int256 answer, , uint256 updatedAt, ) = agg.latestRoundData();
        require(updatedAt > block.timestamp - 24 hours, "Voodoo Finance: STALE_CHAINLINK_PRICE");
        require(answer >= 0, "Voodoo Finance: NEGATIVE_CHAINLINK_PRICE");
        int decimals = 18 - int(IToken(asset).decimals()) - int(agg.decimals());
        if (decimals < 0) {
            return amount.mul(uint(answer)).div(10 ** uint(-decimals));
        } else {
            return amount.mul(uint(answer)).mul(10 ** uint(decimals));
        }
    }

}