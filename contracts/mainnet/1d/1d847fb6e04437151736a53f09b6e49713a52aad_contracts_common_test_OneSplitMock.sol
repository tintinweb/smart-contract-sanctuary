pragma solidity ^0.6.0;

import "../interfaces/OneSplit.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title OneSplit Mock that allows manual price injection.
 */
contract OneSplitMock is OneSplit {
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    mapping(bytes32 => uint256) prices;

    receive() external payable {}

    // Sets price of 1 FROM = <PRICE> TO
    function setPrice(
        address from,
        address to,
        uint256 price
    ) external {
        prices[keccak256(abi.encodePacked(from, to))] = price;
    }

    function getExpectedReturn(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
    ) public override view returns (uint256 returnAmount, uint256[] memory distribution) {
        returnAmount = prices[keccak256(abi.encodePacked(fromToken, destToken))] * amount;

        return (returnAmount, distribution);
    }

    function swap(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 flags
    ) public override payable returns (uint256 returnAmount) {
        uint256 amountReturn = prices[keccak256(abi.encodePacked(fromToken, destToken))] * amount;

        require(amountReturn >= minReturn, "Min Amount not reached");

        if (destToken == ETH_ADDRESS) {
            msg.sender.transfer(amountReturn);
        } else {
            require(IERC20(destToken).transfer(msg.sender, amountReturn), "erc20-send-failed");
        }
    }
}
