/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

pragma solidity 0.5.16;

interface IToken {
    function mint(address _to, uint256 _value) external;

    function burn(address _to, uint256 _value) external;

    function transfer(address recipient, uint256 amount) external;

    function transferFrom(address sender, address recipient, uint256 amount) external;

    function balanceOf(address _owner) external view returns (uint256);
}

interface IToken1 {
    function mint(address _to, uint256 _value) external;

    function burn(address _to, uint256 _value) external;

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external;

    function balanceOf(address _owner) external view returns (uint256);
}


contract idleUnderlyingTestnet {
    address public idleUnderlying = address(0x0cCDf54553e1C4DaB264E3CB3e453dd864321EEb);
    address public idle = address(0xf86303f85747fFDb873DA97FFD15D40A6Ac075b8);
    address public underlying = address(0x87c74f9a8af61e2Ef33049E299dF919a17792115);
    address public comp = address(0x5d4046DBDAfdbB5B34861a266186e31d5F8B4920);

    function getPrice() public view returns (uint256){
        return block.number - 23640000;
    }

    function mintIdleToken(uint256 _amount, bool _skipRebalance, address _referral) external returns (uint256 mintedTokens){
        IToken(underlying).transferFrom(msg.sender, address(this), _amount);
        mintedTokens = _amount * 10 ** 18 / getPrice();
        IToken(idleUnderlying).mint(msg.sender, mintedTokens);
    }

    function redeemIdleToken(uint256 _amount) external returns (uint256 redeemedTokens){
        redeemedTokens = _amount * getPrice() / 10 ** 18;
        IToken(idleUnderlying).burn(msg.sender, _amount);
        IToken(underlying).transfer(msg.sender, redeemedTokens);
        IToken(idle).mint(msg.sender, redeemedTokens / 30);
        IToken(comp).transfer(msg.sender, redeemedTokens / 50);
    }

    function balanceOf(address who) public view returns (uint256){
        return IToken(idleUnderlying).balanceOf(who);
    }


    function getRedeemPrice(address idleYieldToken) view external returns (uint256){
        return getPrice();
    }

    function getRedeemPrice(address idleYieldToken, address user) view external returns (uint256){
        return getPrice();
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts){
        if (address(path[0]) == comp) {
            IToken(path[0]).transfer(address(this), amountIn);
            IToken(idle).mint(to, amountIn * 6);
        } else if (address(path[0]) == idle) {
            IToken1(path[0]).transfer(address(this), amountIn);
            IToken(underlying).transfer(to, amountIn * 8);
        }
        amounts = new uint256[](3);
        amounts[0] = amountIn;
        return amounts;
    }
}