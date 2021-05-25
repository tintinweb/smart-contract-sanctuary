/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

contract testting {
    uint8[4] public winningNumbers;
    address admin;
    address primary;
    
    event No(uint8 _no);
    constructor(address _primary) public {
        admin = msg.sender;
        primary = _primary;
    }

    modifier onlyOwner() {
        require(msg.sender == admin);
        _;
    }
    
    function drawing() external returns(uint8[4] memory) {
        require(msg.sender == primary);
        return (winningNumbers);
        bytes32 _structHash;
        uint256 _randomNumber;
        uint8 _maxNumber;
        uint256 _externalRandomNumber;
        bytes32 _blockhash = blockhash(block.number-1);
        uint256 gasleft = gasleft();

        // 1
        _structHash = keccak256(
            abi.encode(
                _blockhash,
                gasleft,
                _externalRandomNumber
            )
        );
        _randomNumber  = uint256(_structHash);
        assembly {_randomNumber := add(mod(_randomNumber, _maxNumber),1)}
        winningNumbers[0]=uint8(_randomNumber);
        emit No(uint8(_randomNumber));
        // 2
        _structHash = keccak256(
            abi.encode(
                _blockhash,
                block.coinbase,
                gasleft,
                _externalRandomNumber
            )
        );
        _randomNumber  = uint256(_structHash);
        assembly {_randomNumber := add(mod(_randomNumber, _maxNumber),1)}
        winningNumbers[1]=uint8(_randomNumber);
        emit No(uint8(_randomNumber));

        // 3
        _structHash = keccak256(
            abi.encode(
                _blockhash,
                block.timestamp,
                gasleft,
                _externalRandomNumber
            )
        );
        _randomNumber  = uint256(_structHash);
        assembly {_randomNumber := add(mod(_randomNumber, _maxNumber),1)}
        winningNumbers[2]=uint8(_randomNumber);
        emit No(uint8(_randomNumber));

        // 4
        _structHash = keccak256(
            abi.encode(
                _blockhash,
                block.difficulty,
                gasleft,
                _externalRandomNumber
            )
        );
        _randomNumber  = uint256(_structHash);
        assembly {_randomNumber := add(mod(_randomNumber, _maxNumber),1)}
        winningNumbers[3]=uint8(_randomNumber);
        emit No(uint8(_randomNumber));

    }
    
    function findWinningNumbers(uint8[4] memory _randomNumber) external onlyOwner {
        winningNumbers = _randomNumber;
    }

    function changePrimaryAddress(address _primary) external onlyOwner {
        require(_primary != address(0));
        primary = _primary;
    }

    function changeAdminAddress(address _admin) external onlyOwner {
        require(_admin != address(0));
        admin = _admin;
    }
}