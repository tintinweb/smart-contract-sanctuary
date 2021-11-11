//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

// import "hardhat/console.sol";


contract Crowdsale is Ownable {
    using SafeMath for uint256;

    address public TOKEN_ADDRESS;
    uint256 public RATE;
    uint256 public TOTAL_RAISED;

    constructor(address _token_address, uint256 _rate) {
      TOKEN_ADDRESS = _token_address;
      RATE = _rate;
    }

    function buy(address _beneficiary) public payable returns(bool){
        uint256 weiAmount = msg.value;

        _preValidatePurchase(_beneficiary, weiAmount);

        uint256 tokens = _getTokenAmount(weiAmount);
    
        TOTAL_RAISED = TOTAL_RAISED.add(weiAmount);

        _deliverTokens(_beneficiary, tokens);

        return true;

    }

    function _getTokenAmount(uint256 _weiAmount) internal view returns(uint256) {
        return _weiAmount.mul(RATE);
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

    function withdraw() public onlyOwner returns(bool){
        payable(owner()).transfer(address(this).balance);
        return true;
    }

    function withdrawToken(uint256 _weiAmount) public onlyOwner returns(bool){
        _deliverTokens(owner(), _weiAmount);
        return true;
    }




}