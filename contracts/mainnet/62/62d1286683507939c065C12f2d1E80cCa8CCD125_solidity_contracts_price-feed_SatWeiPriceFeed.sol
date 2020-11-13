pragma solidity 0.5.17;

import {SafeMath} from "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../external/IMedianizer.sol";
import "../interfaces/ISatWeiPriceFeed.sol";

/// @notice satoshi/wei price feed.
/// @dev Used ETH/USD medianizer values converted to sat/wei.
contract SatWeiPriceFeed is Ownable, ISatWeiPriceFeed {
    using SafeMath for uint256;

    bool private _initialized = false;
    address internal tbtcSystemAddress;

    IMedianizer[] private ethBtcFeeds;

    constructor() public {
    // solium-disable-previous-line no-empty-blocks
    }

    /// @notice Initialises the addresses of the ETHBTC price feeds.
    /// @param _tbtcSystemAddress Address of the `TBTCSystem` contract. Used for access control.
    /// @param _ETHBTCPriceFeed The ETHBTC price feed address.
    function initialize(
        address _tbtcSystemAddress,
        IMedianizer _ETHBTCPriceFeed
    )
        external onlyOwner
    {
        require(!_initialized, "Already initialized.");
        tbtcSystemAddress = _tbtcSystemAddress;
        ethBtcFeeds.push(_ETHBTCPriceFeed);
        _initialized = true;
    }

    /// @notice Get the current price of 1 satoshi in wei.
    /// @dev This does not account for any 'Flippening' event.
    /// @return The price of one satoshi in wei.
    function getPrice()
        external onlyTbtcSystem view returns (uint256)
    {
        bool ethBtcActive = false;
        uint256 ethBtc = 0;

        for(uint i = 0; i < ethBtcFeeds.length; i++){
            (ethBtc, ethBtcActive) = ethBtcFeeds[i].peek();
            if(ethBtcActive) {
                break;
            }
        }

        require(ethBtcActive, "Price feed offline");

        // convert eth/btc to sat/wei
        // We typecast down to uint128, because the first 128 bits of
        // the medianizer value is unrelated to the price.
        return uint256(10**28).div(uint256(uint128(ethBtc)));
    }

    /// @notice Get the first active Medianizer contract from the ethBtcFeeds array.
    /// @return The address of the first Active Medianizer. address(0) if none found
    function getWorkingEthBtcFeed() external view returns (address){
        bool ethBtcActive;

        for(uint i = 0; i < ethBtcFeeds.length; i++){
            (, ethBtcActive) = ethBtcFeeds[i].peek();
            if(ethBtcActive) {
                return address(ethBtcFeeds[i]);
            }
        }
        return address(0);
    }

    /// @notice Add _newEthBtcFeed to internal ethBtcFeeds array.
    /// @dev IMedianizer must be active in order to add.
    function addEthBtcFeed(IMedianizer _newEthBtcFeed) external onlyTbtcSystem {
        bool ethBtcActive;
        (, ethBtcActive) = _newEthBtcFeed.peek();
        require(ethBtcActive, "Cannot add inactive feed");
        ethBtcFeeds.push(_newEthBtcFeed);
    }

    /// @notice Function modifier ensures modified function is only called by tbtcSystemAddress.
    modifier onlyTbtcSystem(){
        require(msg.sender == tbtcSystemAddress, "Caller must be tbtcSystem contract");
        _;
    }
}
