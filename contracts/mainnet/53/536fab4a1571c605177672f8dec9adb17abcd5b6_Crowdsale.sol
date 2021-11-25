//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";

contract Crowdsale is Ownable {

    address public TOKEN_ADDRESS;
    uint256 public RATE;
    uint256 public TOTAL_RAISED;

    event Buy(address indexed beneficiary, uint256 value, uint256  tokens);

    constructor(uint256 _rate) {
      TOKEN_ADDRESS = 0xBbf5607c6DB9eD5a9F1b118cb99777B2475B3cAC;
      RATE = _rate;
    }

    function buy(address _beneficiary) public payable returns(uint256){
        uint256 weiAmount = msg.value;

        _preValidatePurchase(_beneficiary, weiAmount);

        uint256 tokens = _getTokenAmount(weiAmount);
    
        TOTAL_RAISED = TOTAL_RAISED + weiAmount;

        _deliverTokens(_beneficiary, tokens);

        emit Buy(_beneficiary, weiAmount,  tokens);

        return tokens;

    }

    function _getTokenAmount(uint256 _weiAmount) internal view returns(uint256) {
        return _weiAmount * RATE;
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)internal pure{
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }
    
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        IERC20(TOKEN_ADDRESS).transfer(_beneficiary, _tokenAmount);
    }

    function setRate(uint256 _rate) public onlyOwner returns(bool){
        RATE = _rate;
        return true;
    }

    function setToken(address _tokenAddress) public onlyOwner returns(bool){
        TOKEN_ADDRESS = _tokenAddress;
        return true;
    }

    function withdraw() public onlyOwner returns(bool){
        payable(owner()).transfer(address(this).balance);
        return true;
    }

    function withdrawToken(uint256 _weiAmount) public onlyOwner returns(bool){
        _deliverTokens(owner(), _weiAmount);
        return true;
    }




}