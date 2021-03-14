/**
 *Submitted for verification at Etherscan.io on 2021-03-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract SimpleRandom {
    uint8 private maxNumber = 10; // 0 - 9

    uint256 public issueIndex = 0;
    uint256 public totalAddresses = 0;
    uint256 public totalAmount = 0;
    uint256 public lastTimestamp;

    uint8[6] public winningNumbers;

    // issueId => winningNumbers[numbers]
    mapping(uint256 => uint8[6]) public historyNumbers;
    // address => [number that user has buy]
    mapping(address => uint8[6][]) public userInfo;
    // adminAddress
    address public adminAddress;

    event Buy(address indexed user, uint256 price);
    event Drawing(uint256 indexed issueIndex, uint8[6] winningNumbers);
    event Reset(uint256 indexed issueIndex);

    constructor() public {
        adminAddress = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "admin only");
        _;
    }

    function drawing(uint256 _externalRandomNumber) external onlyAdmin {
        bytes32 _structHash;
        uint256 _randomNumber;
        uint8 _maxNumber = maxNumber;
        bytes32 _blockhash = blockhash(block.number - 1);

        uint256 gasLeft = gasleft();

        // 1
        _structHash = keccak256(
            abi.encode(
                _blockhash,
                totalAddresses,
                gasLeft,
                _externalRandomNumber
            )
        );
        _randomNumber = uint256(_structHash);
        assembly {
            _randomNumber := mod(_randomNumber, _maxNumber)
        }
        winningNumbers[0] = uint8(_randomNumber);

        // 2
        _structHash = keccak256(
            abi.encode(_blockhash, totalAmount, gasLeft, _externalRandomNumber)
        );
        _randomNumber = uint256(_structHash);
        assembly {
            _randomNumber := mod(_randomNumber, _maxNumber)
        }
        winningNumbers[1] = uint8(_randomNumber);

        // 3
        _structHash = keccak256(
            abi.encode(
                _blockhash,
                lastTimestamp,
                gasLeft,
                _externalRandomNumber
            )
        );
        _randomNumber = uint256(_structHash);
        assembly {
            _randomNumber := mod(_randomNumber, _maxNumber)
        }
        winningNumbers[2] = uint8(_randomNumber);

        // 4
        _structHash = keccak256(
            abi.encode(_blockhash, gasLeft, _externalRandomNumber)
        );
        _randomNumber = uint256(_structHash);
        assembly {
            _randomNumber := mod(_randomNumber, _maxNumber)
        }
        winningNumbers[3] = uint8(_randomNumber);

        // 5
        _structHash = keccak256(
            abi.encode(_blockhash, lastTimestamp, _externalRandomNumber)
        );
        _randomNumber = uint256(_structHash);
        assembly {
            _randomNumber := mod(_randomNumber, _maxNumber)
        }
        winningNumbers[4] = uint8(_randomNumber);

        // 6
        _structHash = keccak256(
            abi.encode(_blockhash, totalAddresses, _externalRandomNumber)
        );
        _randomNumber = uint256(_structHash);
        assembly {
            _randomNumber := mod(_randomNumber, _maxNumber)
        }
        winningNumbers[5] = uint8(_randomNumber);

        historyNumbers[issueIndex] = winningNumbers;
        emit Drawing(issueIndex, winningNumbers);
    }

    function reset() external onlyAdmin {
        lastTimestamp = block.timestamp;
        totalAddresses = 0;
        totalAmount = 0;
        winningNumbers[0] = 0;
        winningNumbers[1] = 0;
        winningNumbers[2] = 0;
        winningNumbers[3] = 0;
        winningNumbers[4] = 0;
        winningNumbers[5] = 0;
        issueIndex = issueIndex + 1;
        emit Reset(issueIndex);
    }

    function buy(uint256 _price, uint8[6] memory _numbers) external {
        if (userInfo[msg.sender].length == 0) {
            totalAddresses = totalAddresses + 1;
        }
        totalAmount = totalAmount + _price; // caution overflow!
        userInfo[msg.sender].push(_numbers);
        lastTimestamp = block.timestamp;
        emit Buy(msg.sender, _price);
    }

    // Update admin address by the previous dev.
    function setAdmin(address _adminAddress) public onlyAdmin {
        adminAddress = _adminAddress;
    }
}