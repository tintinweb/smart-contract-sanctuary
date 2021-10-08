// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Utils.sol";

contract SafeTrade is Ownable, ReentrancyGuard {
    uint fee; // ex fee 100 --> 1.00% 
    address feeWallet;    
    mapping(uint => address) defaultTokens; // For frontend query use
    uint defaultTokenId;

    event utilityTransferred(uint _amt, uint _fee, address _from, address _to);
    event tokenTransferred(uint _amt, uint _fee, address _from, address _to);
    event feeWalletSet(address _newVal);
    event feeSet(uint _newVal);
    event defaultTokenAdded(address _newToken);


    constructor(address _feeWallet, uint _fee) {
        feeWallet = _feeWallet;
        fee = _fee;
    }

    /*
    ** User functions
    */

    function transferUtility (address _to) payable public nonReentrant {
        uint feeAmt = msg.value * fee / 10000;        
        payable(feeWallet).transfer(feeAmt);
        payable(_to).transfer(msg.value - feeAmt);
        emit utilityTransferred(msg.value, feeAmt, msg.sender, _to);
    }

    function transferToken(address _token, address _to, uint _amt) public nonReentrant {
        uint feeAmt = _amt * fee / 10000;
        IERC20 token = IERC20(_token);

        token.transferFrom(msg.sender, _to, _amt - feeAmt);
        token.transferFrom(msg.sender, feeWallet, feeAmt);
        emit tokenTransferred(_amt, feeAmt, msg.sender, _to);
    }

    /*
    ** Owner functions
    */

    function setFeeWallet(address _newVal) external onlyOwner {
        feeWallet = _newVal;
        emit feeWalletSet(_newVal);
    }

    function setFee(uint _newVal) external onlyOwner {
        require(_newVal < 10000, "Fee cannot be set >= 100%");
        fee = _newVal;
        emit feeSet(_newVal);
    }

    function addDefaultToken(address _newToken) public onlyOwner {
        require(!tokenIsDuplicated(_newToken), "The token is already in the list");
        defaultTokenId ++;
        defaultTokens[defaultTokenId] = _newToken;
        emit defaultTokenAdded(_newToken);
    }

    /*
    ** Internal Utils
    */

    function tokenIsDuplicated(address _token) internal view returns(bool){
        for (uint i = 1; i <= defaultTokenId; i++){
            if (defaultTokens[i] == _token) {
                return true;
            }
        }
        return false;
    }

    /*
    ** External Utils
    */

    function fetchDefaultTokens() public view returns(address[] memory) {
        address[] memory _defaultTokens = new address[](defaultTokenId);
        for (uint i; i < defaultTokenId; i++){
            _defaultTokens[i] = defaultTokens[i+1];
        }
        return _defaultTokens;
    }

}