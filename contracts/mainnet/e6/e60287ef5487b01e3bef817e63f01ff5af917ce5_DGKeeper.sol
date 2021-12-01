/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// SPDX-License-Identifier: --DG--

pragma solidity ^0.8.9;

contract DGKeeper {

    address public gateKeeper;
    address public gateOverseer;
    address public distributionToken;
    uint256 public totalRequired;

    uint256 immutable MIN_TIME_FRAME;
    address immutable ZERO_ADDRESS;

    struct KeeperInfo {
        bool isImmutable;
        uint256 keeperRate;
        uint256 keeperFrom;
        uint256 keeperTill;
        uint256 keeperBalance;
        uint256 keeperPayouts;
    }

    mapping(address => KeeperInfo) public keeperList;

    modifier onlyGateKeeper() {
        require(
            msg.sender == gateKeeper,
            'DGKeeper: keeper denied!'
        );
        _;
    }

    modifier onlyGateOverseer() {
        require(
            msg.sender == gateOverseer,
            'DGKeeper: overseer denied!'
        );
        _;
    }

    event tokensScraped (
        address indexed scraper,
        uint256 scrapedAmount,
        uint256 timestamp
    );

    event recipientCreated (
        address indexed recipient,
        uint256 timeLock,
        uint256 timeReward,
        uint256 instantReward,
        uint256 timestamp,
        bool isImmutable
    );

    event recipientDestroyed (
        address indexed recipient,
        uint256 timestamp
    );

    constructor(
        address _distributionToken,
        address _gateOverseer,
        address _gateKeeper,
        uint256 _minTimeFrame
    ) {
        require(
            _minTimeFrame > 0,
            'DGKeeper: increase _timeFrame'
        );

        distributionToken = _distributionToken;
        gateOverseer = _gateOverseer;
        gateKeeper = _gateKeeper;
        MIN_TIME_FRAME = _minTimeFrame;
        ZERO_ADDRESS = address(0);
    }

    function allocateTokensBulk(
        address[] memory _recipients,
        uint256[] memory _tokensOpened,
        uint256[] memory _tokensLocked,
        uint256[] memory _timeFrame,
        bool[] memory _immutable
    )
        external
        onlyGateKeeper
    {
        for (uint256 i = 0; i < _recipients.length; i++) {
            allocateTokens(
                _recipients[i],
                _tokensOpened[i],
                _tokensLocked[i],
                _timeFrame[i],
                _immutable[i]
            );
        }
    }

    function allocateTokens(
        address _recipient,
        uint256 _tokensOpened,
        uint256 _tokensLocked,
        uint256 _timeFrame,
        bool _isImmutable
    )
        public
        onlyGateKeeper
    {
        require(
            _timeFrame >= MIN_TIME_FRAME,
            'DGKeeper: _timeFrame below minimum'
        );

        require(
            keeperList[_recipient].keeperFrom == 0,
            'DGKeeper: _recipient is active'
        );

        totalRequired = totalRequired
            + _tokensOpened
            + _tokensLocked;

        _safeBalanceOf(
            distributionToken,
            address(this),
            totalRequired
        );

        uint256 timestamp = getNow();

        keeperList[_recipient].keeperFrom = timestamp;
        keeperList[_recipient].keeperTill = timestamp
            + _timeFrame;

        keeperList[_recipient].keeperRate = _tokensLocked
            / _timeFrame;

        keeperList[_recipient].keeperBalance = _tokensLocked
            % _timeFrame
            + _tokensOpened;

        keeperList[_recipient].isImmutable = _isImmutable;

        emit recipientCreated (
            _recipient,
            _timeFrame,
            _tokensLocked,
            _tokensOpened,
            timestamp,
            _isImmutable
        );
    }

    function scrapeMyTokens()
        external
    {
        _scrapeTokens(
            msg.sender
        );
    }

    function _scrapeTokens(
        address _recipient
    )
        internal
    {
        uint256 scrapeAmount = availableBalance(
            _recipient
        );

        keeperList[_recipient].keeperPayouts =
        keeperList[_recipient].keeperPayouts + scrapeAmount;

        _safeTransfer(
            distributionToken,
            _recipient,
            scrapeAmount
        );

        totalRequired =
        totalRequired - scrapeAmount;

        emit tokensScraped (
            _recipient,
            scrapeAmount,
            block.timestamp
        );
    }

    function destroyRecipient(
        address _recipient
    )
        external
        onlyGateOverseer
    {
        require(
            keeperList[_recipient].isImmutable == false,
            'DGKeeper: _recipient is immutable'
        );

        _scrapeTokens(
            _recipient
        );

        totalRequired =
        totalRequired - lockedBalance(_recipient);

        delete keeperList[_recipient];

        emit recipientDestroyed (
            _recipient,
            block.timestamp
        );
    }

    function availableBalance(
        address _recipient
    )
        public
        view
        returns (uint256 balance)
    {
        uint256 timePassed =
            getNow() < keeperList[_recipient].keeperTill ?
            getNow() - keeperList[_recipient].keeperFrom : _diff(_recipient);

        balance = keeperList[_recipient].keeperRate
            * timePassed
            + keeperList[_recipient].keeperBalance
            - keeperList[_recipient].keeperPayouts;
    }

    function lockedBalance(
        address _recipient
    )
        public
        view
        returns (uint256 balance)
    {
        uint256 timeRemaining =
            keeperList[_recipient].keeperTill > getNow() ?
            keeperList[_recipient].keeperTill - getNow() : 0;

        balance = keeperList[_recipient].keeperRate * timeRemaining;
    }

    function getNow()
        public
        view
        returns (uint256 time)
    {
        time = block.timestamp;
    }

    function changeDistributionToken(
        address _newDistributionToken
    )
        external
        onlyGateKeeper
    {
        distributionToken = _newDistributionToken;
    }

    function renounceKeeperOwnership()
        external
        onlyGateKeeper
    {
        gateKeeper = ZERO_ADDRESS;
    }

    function renounceOverseerOwnership()
        external
        onlyGateOverseer
    {
        gateOverseer = ZERO_ADDRESS;
    }

    function _diff(
        address _recipient
    )
        internal
        view
        returns (uint256 difference)
    {
        difference = keeperList[_recipient].keeperTill - keeperList[_recipient].keeperFrom;
    }

    bytes4 private constant TRANSFER = bytes4(
        keccak256(
            bytes(
                'transfer(address,uint256)'
            )
        )
    );

    bytes4 private constant BALANCEOF = bytes4(
        keccak256(
            bytes(
                'balanceOf(address)'
            )
        )
    );

    function _safeTransfer(
        address _token,
        address _to,
        uint256 _value
    )
        private
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                TRANSFER,
                _to,
                _value
            )
        );

        require(
            success && (
                data.length == 0 || abi.decode(
                    data, (bool)
                )
            ),
            'DGKeeper: TRANSFER_FAILED'
        );
    }

    function _safeBalanceOf(
        address _token,
        address _owner,
        uint256 _required
    )
        private
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                BALANCEOF,
                _owner
            )
        );

        require(
            success && abi.decode(
                data, (uint256)
            ) >= _required,
            'DGKeeper: BALANCEOF_FAILED'
        );
    }
}