//SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "./FlashbotsCheckAndSend.sol";
import "./IWETH.sol";

/*
  Copyright 2021 Kendrick Tan ([email protected]).

  This contract is an extension of flashbot's FlashbotsCheckAndSend.sol
  This contract takes in WETH instead of ETH so that transactions can be signed via a browser.
  But needs to be approved beforehand.
*/

contract MEVBriber is FlashbotsCheckAndSend {
    IWETH public constant weth =
        IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    receive() external payable {}

    function check32BytesAndSendWETH(
        uint256 _bribeAmount,
        address _target,
        bytes memory _payload,
        bytes32 _resultMatch
    ) external {
        _check32Bytes(_target, _payload, _resultMatch);
        weth.transferFrom(msg.sender, address(this), _bribeAmount);
        weth.withdraw(_bribeAmount);
        block.coinbase.transfer(_bribeAmount);
    }

    function check32BytesAndSendMultiWETH(
        uint256 _bribeAmount,
        address[] memory _targets,
        bytes[] memory _payloads,
        bytes32[] memory _resultMatches
    ) external {
        require(_targets.length == _payloads.length);
        require(_targets.length == _resultMatches.length);
        for (uint256 i = 0; i < _targets.length; i++) {
            _check32Bytes(_targets[i], _payloads[i], _resultMatches[i]);
        }
        weth.transferFrom(msg.sender, address(this), _bribeAmount);
        weth.withdraw(_bribeAmount);
        block.coinbase.transfer(_bribeAmount);
    }

    function checkBytesAndSendWETH(
        uint256 _bribeAmount,
        address _target,
        bytes memory _payload,
        bytes memory _resultMatch
    ) external {
        _checkBytes(_target, _payload, _resultMatch);
        weth.transferFrom(msg.sender, address(this), _bribeAmount);
        weth.withdraw(_bribeAmount);
        block.coinbase.transfer(_bribeAmount);
    }

    function checkBytesAndSendMultiWETH(
        uint256 _bribeAmount,
        address[] memory _targets,
        bytes[] memory _payloads,
        bytes[] memory _resultMatches
    ) external {
        require(_targets.length == _payloads.length);
        require(_targets.length == _resultMatches.length);
        for (uint256 i = 0; i < _targets.length; i++) {
            _checkBytes(_targets[i], _payloads[i], _resultMatches[i]);
        }
        weth.transferFrom(msg.sender, address(this), _bribeAmount);
        weth.withdraw(_bribeAmount);
        block.coinbase.transfer(_bribeAmount);
    }
}