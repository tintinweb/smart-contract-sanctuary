// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./IUniswapV2Factory.sol";
import "./OwnableUpgradeSafe.sol";
import "./IERC20.sol";

contract XAUTransferHandler is OwnableUpgradeSafe {

    using SafeMath for uint256;
    address tokenUniswapPairXAU;
    address[] public trackedPairs;
    uint16 public feePercentX100;
    bool public transfersPaused;
    mapping (address => bool) public noFeeList;
    mapping (address => bool) public isPair;

    event NewTransfersPaused(bool oldTransfersPaused, bool newTransfersPaused);    
    event NewFeePercentX100(uint256 oldFeePercentX100, uint256 newFeePercentX100);

    function initialize(
        address _tokenUniswapPairXAU,
        address _xauVault,
        uint16 _feePercentX100
    ) public initializer {
        tokenUniswapPairXAU = _tokenUniswapPairXAU;
        OwnableUpgradeSafe.__Ownable_init();
        feePercentX100 = _feePercentX100;
        transfersPaused = true;
        _editNoFeeList(_xauVault, true);
        _addPairToTrack(tokenUniswapPairXAU);
    }

    function addPairToTrack(address pair) onlyOwner public {
        _addPairToTrack(pair);
    }

    function setNewTokenUniswap(address _tokenUniswapPairXAU) public onlyOwner {
        tokenUniswapPairXAU = _tokenUniswapPairXAU;
        _addPairToTrack(tokenUniswapPairXAU);
    }

    function _addPairToTrack(address pair) internal {

        uint256 length = trackedPairs.length;
        for (uint256 i = 0; i < length; i++) {
            require(trackedPairs[i] != pair, "Pair already tracked");
        }
        // we sync
        sync(pair); 
        // we add to array so we can loop over it
        trackedPairs.push(pair);
        // we add pair to no fee sender list
        _editNoFeeList(pair, true);
        // we add it to pair mapping to lookups
        isPair[pair] = true;

    }


    // CORE token is pausable 
    function setTransfersPaused(bool _transfersPaused) public onlyOwner {
        bool oldTransfersPaused = transfersPaused;
        transfersPaused = _transfersPaused;

        // Sync all tracked pairs
        uint256 length = trackedPairs.length;
        for (uint256 i = 0; i < length; i++) {
            sync(trackedPairs[i]);
        }

        emit NewTransfersPaused(oldTransfersPaused, _transfersPaused);    
    }

    function setFeePercentX100(uint16 _feePercentX100) public onlyOwner {
        require(_feePercentX100 <= 1000, 'Fee clamped at 10%');
        uint256 oldFeePercentX100 = feePercentX100;
        feePercentX100 = _feePercentX100;
        emit NewFeePercentX100(oldFeePercentX100, _feePercentX100);
    }

    function editNoFeeList(address _address, bool noFee) public onlyOwner {
        _editNoFeeList(_address, noFee);
    }
    function _editNoFeeList(address _address, bool noFee) internal{
        noFeeList[_address] = noFee;
    }

    // Old sync for backwards compatibility - syncs xautokenEthPair
    function sync() public returns (bool lastIsMint, bool lpTokenBurn) {
        (lastIsMint, lpTokenBurn) = sync(tokenUniswapPairXAU);
    }

    mapping(address => uint256) private lpSupplyOfPair;

    function sync(address pair) public returns (bool lastIsMint, bool lpTokenBurn) {
        uint256 _LPSupplyOfPairNow = IERC20(pair).totalSupply();

        lpTokenBurn = lpSupplyOfPair[pair] > _LPSupplyOfPairNow;
        lpSupplyOfPair[pair] = _LPSupplyOfPairNow;

        lastIsMint = false;
    }

    function handleTransfer
        (address sender, 
        address recipient, 
        uint256 amount
    ) public {
    }

    function calculateAmountsAfterFee(        
        address sender, 
        address recipient, 
        uint256 amount
    ) public returns (uint256 transferToAmount, uint256 transferToFeeDistributorAmount) {
        require(transfersPaused == false, "XAU TransferHandler: Transfers Paused");

        if (isPair[recipient]) {
            sync(recipient);
        }

        if (!isPair[recipient] && !isPair[sender])
            sync();

        if (noFeeList[sender]) {
            transferToFeeDistributorAmount = 0;
            transferToAmount = amount;
        } 
        else {
            // console.log("Normal fee transfer");
            transferToFeeDistributorAmount = amount.mul(feePercentX100).div(10000);
            transferToAmount = amount.sub(transferToFeeDistributorAmount);
        }
    }

}