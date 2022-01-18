// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;



import {Ownable} from "./Ownable.sol";
import {SafeMath} from "./SafeMath.sol";
import {IChainlinkAggregator} from "./IChainlinkAggregator.sol";



/**
 * @title A wrapper proxy for converting ATOM price to uatom price, only for test purpose
 */
contract MockUATOMOracleWrapperProxy is IChainlinkAggregator, Ownable {
    using SafeMath for uint256;
    
    
    IChainlinkAggregator public uatomAggregator;


    event LogSetUATOMAggregator(IChainlinkAggregator indexed oldUATOMAggregator, IChainlinkAggregator indexed newUATOMAggregator);


    constructor(IChainlinkAggregator _uatomAggregator) public {
        setUATOMAggregator(_uatomAggregator);
    }

    function setUATOMAggregator(IChainlinkAggregator _uatomAggregator) public onlyOwner {
        IChainlinkAggregator oldUATOMAggregator = uatomAggregator;
        uatomAggregator = _uatomAggregator;
        emit LogSetUATOMAggregator(oldUATOMAggregator, uatomAggregator);
    }

    function latestAnswer() public view virtual override returns (int256 answer) {
        answer = int256(uint256(uatomAggregator.latestAnswer()).div(10**6));
    }

    function latestTimestamp() public view virtual override returns (uint256){
        return uatomAggregator.latestTimestamp();
    }

    function latestRound() public view virtual override returns (uint256) {
        return uatomAggregator.latestRound();
    }

    function getAnswer(uint256 _roundId) public view virtual override returns (int256) {
        return uatomAggregator.getAnswer(_roundId);
    }

    function getTimestamp(uint256 _roundId) public view virtual override returns (uint256) {
        return uatomAggregator.getTimestamp(_roundId);
    }
}