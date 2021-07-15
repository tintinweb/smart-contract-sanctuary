// SPDX-License-Identifier: -- 💰️ --

pragma solidity ^0.8.0;

import "./Interfaces.sol";

contract WiseFunder {

    ITokenContract public immutable WISE_TOKEN;

    address public immutable FUND_OWNER;
    uint256 public immutable THRESHOLD;
    uint256 public immutable TIMESTAMP;

    uint256 public totalFunded;
    uint256 public totalFunders;

    bool public hasClaimed;

    mapping(address => uint256) public balanceMap;
    mapping(uint256 => address) public fundersMap;

    event FundraiserCreated(
        address indexed fundOwner,
        uint256 amount,
        uint256 timestamp
    );

    event NewFunder(
        uint256 indexed funderIndex,
        address indexed funderAddress,
        uint256 tokenAmount
    );

    event FundsAdded(
        address indexed funderAddress,
        uint256 tokenAmount
    );

    event FundsClaimed(
        address indexed fundOwner,
        uint256 totalFunded
    );

    event RefundIssued(
        address indexed refundAddress,
        uint256 amount
    );

    modifier onlyOwner {
        require(
            msg.sender == FUND_OWNER,
            'WiseFunder: invalid address'
        );
        _;
    }

    modifier fundingOpen {
        require(
            block.timestamp < TIMESTAMP,
            'WiseFunder: funding closed'
        );
        _;
    }

    modifier fundingClosed {
        require(
            block.timestamp >= TIMESTAMP,
            'WiseFunder: ongoing funding'
        );
        _;
    }

    constructor(
        address _wiseToken,
        address _fundOwner,
        uint256 _tokenAmount,
        uint256 _timeAmount
    ) {
        WISE_TOKEN = ITokenContract(
            _wiseToken
        );

        FUND_OWNER = _fundOwner;
        THRESHOLD = _tokenAmount;
        TIMESTAMP = block.timestamp + _timeAmount;

        emit FundraiserCreated(
            _fundOwner,
            _tokenAmount,
            _timeAmount
        );
    }

    function fundTokens(
        uint256 _tokenAmount
    )
        external
        fundingOpen
    {
        require(
            totalFunded < THRESHOLD,
            'WiseFunder: already funded'
        );

        _fundTokens(msg.sender, address(this),
            _adjustAmount(totalFunded, _tokenAmount,
                THRESHOLD
            )
        );
    }

    function _fundTokens(
        address _funderAddress,
        address _contractAddress,
        uint256 _funderAmount
    )
        private
    {
        WISE_TOKEN.transferFrom(
            _funderAddress,
            _contractAddress,
            _funderAmount
        );

        _traceBalanceMap(
            _funderAddress,
            _funderAmount
        );

        totalFunded =
        totalFunded + _funderAmount;

        emit FundsAdded(
            _funderAddress,
            _funderAmount
        );
    }

    function claimToken()
        external
        onlyOwner
    {
        require(
            totalFunded >= THRESHOLD,
            'WiseFunder: not funded'
        );

        require(
            hasClaimed == false,
            'WiseFunder: already claimed'
        );

        hasClaimed = true;

        WISE_TOKEN.transfer(
            FUND_OWNER,
            totalFunded
        );

        emit FundsClaimed(
            FUND_OWNER,
            totalFunded
        );
    }

    function refundTokens()
        external
        fundingClosed
    {
        require(
            totalFunded < THRESHOLD,
            'WiseFunder: funded'
        );

        _refundTokens(
            msg.sender,
            balanceMap[msg.sender]
        );
    }

    function _refundTokens(
        address _refundAddress,
        uint256 _refundAmount
    )
        private
    {
        balanceMap[_refundAddress] = 0;

        WISE_TOKEN.transfer(
            _refundAddress,
            _refundAmount
        );

        emit RefundIssued(
            _refundAddress,
            _refundAmount
        );
    }

    function _traceBalanceMap(
        address _funderAddress,
        uint256 _funderAmount
    )
        private
    {
        if (balanceMap[_funderAddress] == 0) {
            _fundersIncrease(
                _funderAddress,
                _funderAmount
            );
        }

        _balanceIncrease(
            _funderAddress,
            _funderAmount
        );
    }

    function _balanceIncrease(
        address _funderAddress,
        uint256 _funderAmount
    )
        private
    {
        balanceMap[_funderAddress] =
        balanceMap[_funderAddress] + _funderAmount;
    }

    function _fundersIncrease(
        address _funderAddress,
        uint256 _funderAmount
    )
        private
    {
        totalFunders =
        totalFunders + 1;

        fundersMap[totalFunders] = _funderAddress;

        emit NewFunder(
            totalFunders,
            _funderAddress,
            _funderAmount
        );
    }

    function _adjustAmount(
        uint256 _totalFunded,
        uint256 _tokenAmount,
        uint256 _thresholdAmount
    )
        private
        pure
        returns (uint256)
    {
        return _isOverflow(
            _tokenAmount,
            _totalFunded,
            _thresholdAmount
        )
            ? _thresholdAmount - _totalFunded
            : _tokenAmount;
    }

    function _isOverflow(
        uint256 _totalFunded,
        uint256 _tokenAmount,
        uint256 _thresholdValue
    )
        private
        pure
        returns (bool)
    {
        return _totalFunded + _tokenAmount > _thresholdValue;
    }
}