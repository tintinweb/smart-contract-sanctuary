pragma solidity ^0.8.3;

import {Daf} from "./Daf.sol";

contract DafFactory {
    Daf[] public dafs;

    address[] public currencies;

    event DafCreated(Daf daf);

    constructor(address[] memory _currencies) {
        currencies = _currencies;
    }

    function create(
        string memory _name,
        string memory _symbol,
        address _currency,
        uint256 _totalSupply,
        uint256 _governanceTokensPrice,
        uint256 _percentToVote,
        uint256 _limitToBuy,
        uint256 _votingDuration
    ) external {
        bool _validCurrency;

        for (uint256 i = 0; i < currencies.length; i++) {
            if (_currency == currencies[i]) {
                _validCurrency = true;
                break;
            }
        }

        require(_validCurrency);

        Daf daf =
            new Daf(
                _name,
                _symbol,
                _currency,
                msg.sender,
                _totalSupply,
                _governanceTokensPrice,
                _percentToVote,
                _limitToBuy,
                _votingDuration
            );

        dafs.push(daf);

        emit DafCreated(daf);
    }

    function getDafs() external view returns (Daf[] memory) {
        return dafs;
    }
}