/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

contract OneRoleAccessControlWithTimeLock {
    uint256 private constant TIME_LOCK_DURATION = 1 minutes;

    // Below are the variables which consume storage slots.
    address public moreSecuredOperator;
    address public pendingMoreSecuredOperator;
    address public lessSecuredOperator;
    address public errandOperator;
    address public sentinel;
    address public allowanceTarget;
    mapping(address => bool) private authorized;
    mapping(address => bool) private blacklists;
    uint256 public numPendingAuthorized;
    mapping(uint256 => address) public pendingAuthorized;
    uint256 public timelockExpirationTime;
    uint256 public contractDeployedTime;
    bool public timelockActivated;

    // System events
    event TimeLockActivated(uint256 activatedTimeStamp);
    // Operator events
    event TransferMoreSecuredOperator(address newMoreSecuredOperator);
    event TransferLessSecuredOperator(address newLessSecuredOperator);
    event TransferErrandOperator(address newErrandOperator);
    event TearDown(uint256 tearDownTimeStamp);
    event BlackListToken(address token, bool isBlacklisted);
    event AuthorizeSpender(address spender, bool isAuthorized);

    /************************************************************
     *          Access control and ownership management          *
     *************************************************************/
    modifier onlyMoreSecuredOperator() {
        require(moreSecuredOperator == msg.sender, "OneRoleAccessControl: not the moreSecuredOperator");
        _;
    }

    modifier onlyLessSecuredOperator() {
        require(lessSecuredOperator == msg.sender, "OneRoleAccessControl: not the lessSecuredOperator");
        _;
    }

    modifier onlyErrandOperator() {
        require(errandOperator == msg.sender, "OneRoleAccessControl: not the errandOperator");
        _;
    }

    modifier onlyAuthorized() {
        require(authorized[msg.sender], "Spender: not authorized");
        _;
    }

    function setNewMoreSecuredOperator(address _newMoreSecuredOperator) external onlyMoreSecuredOperator {
        require(_newMoreSecuredOperator != address(0), "Spender: moreSecuredOperator can not be zero address");
        pendingMoreSecuredOperator = _newMoreSecuredOperator;
    }

    function acceptAsMoreSecuredOperator() external {
        require(pendingMoreSecuredOperator == msg.sender, "Spender: only nominated one can accept as new moreSecuredOperator");
        pendingMoreSecuredOperator = address(0);
        emit TransferMoreSecuredOperator(msg.sender);
    }

    function transferLessSecuredOperator(address _newLessSecuredOperator) external onlyMoreSecuredOperator {
        require(_newLessSecuredOperator != address(0), "OneRoleAccessControl: lessSecuredOperator can not be zero address");

        emit TransferLessSecuredOperator(_newLessSecuredOperator);
    }

    function transferErrandOperator(address _newErrandOperator) external onlyLessSecuredOperator {
        require(_newErrandOperator != address(0), "OneRoleAccessControl: errandOperator can not be zero address");

        emit TransferErrandOperator(_newErrandOperator);
    }

    /************************************************************
     *                    Timelock management                    *
     *************************************************************/
    /// @dev Everyone can activate timelock after the contract has been deployed for more than 1 day.
    function activateTimelock() external {
        bool canActivate = (block.timestamp - contractDeployedTime) > 1 days;
        require(canActivate && !timelockActivated, "Spender: can not activate timelock yet or has been activated");
        timelockActivated = true;

        emit TimeLockActivated(block.timestamp);
    }

    /************************************************************
     *              Constructor and init functions               *
     *************************************************************/
    constructor(
        address _moreSecuredOperator,
        address _lessSecuredOperator,
        address _errandOperator
    ) {
        moreSecuredOperator = _moreSecuredOperator;
        lessSecuredOperator = _lessSecuredOperator;
        errandOperator = _errandOperator;
        timelockActivated = false;
        contractDeployedTime = block.timestamp;
    }

    /************************************************************
     *          teardown functions            *
     *************************************************************/

    function teardown() external onlyMoreSecuredOperator {
        emit TearDown(block.timestamp);
    }

    /************************************************************
     *           Whitelist and blacklist functions               *
     *************************************************************/
    function isBlacklisted(address _tokenAddr) external view returns (bool) {
        return blacklists[_tokenAddr];
    }

    function blacklist(address[] calldata _tokenAddrs, bool[] calldata _isBlacklisted) external onlyErrandOperator {
        require(_tokenAddrs.length == _isBlacklisted.length, "Spender: length mismatch");
        for (uint256 i = 0; i < _tokenAddrs.length; i++) {
            blacklists[_tokenAddrs[i]] = _isBlacklisted[i];

            emit BlackListToken(_tokenAddrs[i], _isBlacklisted[i]);
        }
    }

    function isAuthorized(address _caller) external view returns (bool) {
        return authorized[_caller];
    }

    function authorize(address[] calldata _pendingAuthorized) external onlyLessSecuredOperator {
        require(_pendingAuthorized.length > 0, "Spender: authorize list is empty");
        require(numPendingAuthorized == 0 && timelockExpirationTime == 0, "Spender: an authorize current in progress");

        if (timelockActivated) {
            numPendingAuthorized = _pendingAuthorized.length;
            for (uint256 i = 0; i < _pendingAuthorized.length; i++) {
                require(_pendingAuthorized[i] != address(0), "Spender: can not authorize zero address");
                pendingAuthorized[i] = _pendingAuthorized[i];
            }
            timelockExpirationTime = block.timestamp + TIME_LOCK_DURATION;
        } else {
            for (uint256 i = 0; i < _pendingAuthorized.length; i++) {
                require(_pendingAuthorized[i] != address(0), "Spender: can not authorize zero address");
                authorized[_pendingAuthorized[i]] = true;

                emit AuthorizeSpender(_pendingAuthorized[i], true);
            }
        }
    }

    function completeAuthorize() external {
        require(timelockExpirationTime != 0, "Spender: no pending authorize");
        require(block.timestamp >= timelockExpirationTime, "Spender: time lock not expired yet");

        for (uint256 i = 0; i < numPendingAuthorized; i++) {
            authorized[pendingAuthorized[i]] = true;
            emit AuthorizeSpender(pendingAuthorized[i], true);
            delete pendingAuthorized[i];
        }
        timelockExpirationTime = 0;
        numPendingAuthorized = 0;
    }

    function deauthorize(address[] calldata _deauthorized) external onlyLessSecuredOperator {
        for (uint256 i = 0; i < _deauthorized.length; i++) {
            if (authorized[_deauthorized[i]]) {
                authorized[_deauthorized[i]] = false;
                emit AuthorizeSpender(_deauthorized[i], false);
            }

            for (uint256 j = 0; j < numPendingAuthorized; j++) {
                if (pendingAuthorized[j] == _deauthorized[i]) {
                    delete pendingAuthorized[i];
                }
            }
        }

    }
}