//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
import "./Ownable.sol";
import "./XBridge.sol";
import "./Address.sol";
import "./XBridgeManager.sol";
import "./IXSurge.sol";

/// @title Contract which Receives xSurge Tokens, redeem them for Surge, and remove them from supply forcefully
/// @author Markymark (SafemoonMark)
contract Burninator is Ownable {

    using Address for address;

    XBridge myBridge;

    XBridgeManager verifier;

    address[] public surgeTokensToBurn;
    address[] public xSurgeTokens;

    uint256 minBurnThreshold = 10**8;
    uint256 minRedeemThreshold = 102 * 10**6;

    constructor() {
        verifier = XBridgeManager(0x9Ae1630066DF94b27f3281Ad080f360aa6BDCc21);
        address ca = verifier.createXBridge(address(this));
        myBridge = XBridge(payable(ca));
    }

    function _redeemSurge() private returns(bool){
        uint8 count = 0;
        for (uint i = 0; i < xSurgeTokens.length; i++) {
            if (IERC20(xSurgeTokens[i]).balanceOf(address(this)) > minRedeemThreshold) {
                _convertToSurge(xSurgeTokens[i]);
                if (count >= 3) return(true);
                else count++;
            }
        }
        return count > 0;
    }

    function redeemSurge() public returns(bool) {
        return _redeemSurge();
    }

    function redeemSpecificSurge(address surgeToRedeem) external onlyOwner {
        _convertToSurge(surgeToRedeem);
    }
    
    function burnIt() public {
        _burnIt();
    }

    function BurnIt() internal {

        _redeemSurge();
        _burnIt();
    }

    function _burnIt() private {
        
        uint256 count = 0;
        for (uint i = 0; i < surgeTokensToBurn.length; i++) {
            uint256 bal = IERC20(surgeTokensToBurn[i]).balanceOf(address(this));
            if (bal >= minBurnThreshold) {
                try IERC20(surgeTokensToBurn[i]).transfer(surgeTokensToBurn[i], bal) {} catch {}
                if (count == 5) {
                    return;
                } else {
                    count++;
                }
            }
        }
    }
    
    function burnSurge(address surge) external {
        uint256 bal = IERC20(surge).balanceOf(address(this));
        if (bal > minBurnThreshold) {
            IERC20(surge).transfer(surge, bal);
        }
    }

    function convertXSurge(address xSurge) external {
        address native = IXSurge(xSurge).getNativeAddress();
        require(native != address(0), 'Native Cannot Be Zero Address');
        _convertToSurge(xSurge);
    }

    function _convertToSurge(address xSurge) private {
        uint256 bal = IERC20(xSurge).balanceOf(address(this));
        try myBridge.sellXTokenForNative(xSurge, bal) {} catch {}
    }

    function getTokenBalance(address token) public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function addTokenAndXToken(address nativeToken, address xToken) external onlyOwner {
        require(nativeToken != address(0) && xToken != address(0), 'cannot add zero address');
        require(IXSurge(xToken).getNativeAddress() == nativeToken, 'Native does not match');
        xSurgeTokens.push(xToken);
        surgeTokensToBurn.push(nativeToken);
    }

    function addSurgeTokenToBurn(address nativeToBurn) public onlyOwner {
        require(nativeToBurn != address(0), 'cannot burn zero address');
        surgeTokensToBurn.push(nativeToBurn);
    }

    function addxSurgeAndSurgeToConvert(address xToken) public onlyOwner {
        address native = IXSurge(xToken).getNativeAddress();
        require(xToken != address(0) && native != address(0), 'cannot burn zero address');
        xSurgeTokens.push(xToken);
        surgeTokensToBurn.push(native);
    }

    function removeXSurgeToken(address token) external onlyOwner {
        
        uint256 index = 0;
        for(uint256 i = 0; i < xSurgeTokens.length; i++) {
            if (xSurgeTokens[i] == token) {
                index = i+1;
                break;
            }
        }
        if (index != 0) {
            address temp = xSurgeTokens[xSurgeTokens.length - 1];
            xSurgeTokens[xSurgeTokens.length - 1] = xSurgeTokens[index - 1];
            xSurgeTokens[index - 1] = temp;
            xSurgeTokens.pop();
        }
    }
    
    function removeSurgeTokenToBurn(address token) external onlyOwner {
        
        uint256 index = 0;
        for(uint256 i = 0; i < surgeTokensToBurn.length; i++) {
            if (surgeTokensToBurn[i] == token) {
                index = i+1;
                break;
            }
        }
        if (index != 0) {
            address temp = surgeTokensToBurn[xSurgeTokens.length - 1];
            surgeTokensToBurn[xSurgeTokens.length - 1] = surgeTokensToBurn[index - 1];
            surgeTokensToBurn[index - 1] = temp;
            surgeTokensToBurn.pop();
        }
    }

    function setMinimumThresholds(uint256 burnThreshold, uint256 redeemThreshold) external onlyOwner {
        minBurnThreshold = burnThreshold;
        minRedeemThreshold = redeemThreshold;
        emit UpdatedThresholds(burnThreshold, redeemThreshold);
    }

    function withdrawTokensSentByMistake(address token, uint256 amount) external onlyOwner {
        uint256 bal = IERC20(token).balanceOf(address(this));
        require (bal > 0 && amount <= bal, 'zero balance or incorrect amount entered');
        amount = amount == 0 ? bal : amount;
        IERC20(token).transfer(msg.sender, amount);
        emit WithdrawMistakes(token, amount);
    }

    /** BNB Sent to Burninator will BURN IT */
    receive() external payable {
        BurnIt();
    }

    // EVENTS
    event UpdatedThresholds(uint256 burnThreshold, uint256 redeemThreshold);
    event WithdrawMistakes(address token, uint256 amount);
}