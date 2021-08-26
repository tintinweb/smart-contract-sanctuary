/**
 *Submitted for verification at Etherscan.io on 2021-08-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract ShitYouDoWhenBored {
    address internal constant TOKEN_WETH  = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant TOKEN_LIDO  = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address internal constant TOKEN_DAI   = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant TOKEN_USDC  = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant PROXY_DYDX  = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
    
    
    function callFunction(
        address sender,
        Types.AccountInfo memory,
        bytes calldata
    ) external {
        require(sender == address(this));
        uint256 amountToMint = IERC20Token(TOKEN_WETH).balanceOf(address(this));
        WETH9(TOKEN_WETH).withdraw(amountToMint);
        IERC20Token(TOKEN_LIDO).submit{value: amountToMint}(0x90102a92e8E40561f88be66611E5437FEb339e79);
        require(IERC20Token(TOKEN_LIDO).totalSupply() >= 1000000 * 10 ** 18);
        uint256 amountToSell = IERC20Token(TOKEN_LIDO).balanceOf(address(this));
        IERC20Token(TOKEN_LIDO).approve(
            0xDC24316b9AE028F1497c275EB9192a3Ea0f67022,
            amountToSell
        );
        Curve(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022).exchange(
            1,
            0,
            amountToSell,
            1
        );
        WETH9(TOKEN_WETH).deposit{value: address(this).balance}();
    }
    
    function wrapWithDyDx(uint256 requiredAmount) public payable {
        require(msg.sender == 0x90102a92e8E40561f88be66611E5437FEb339e79);
        require(IERC20Token(TOKEN_LIDO).totalSupply() < 1000000 * 10 ** 18);
        Types.ActionArgs[] memory operations = new Types.ActionArgs[](3);
        operations[0] = Types.ActionArgs({
            actionType: Types.ActionType.Withdraw,
            accountId: 0,
            amount: Types.AssetAmount({
                sign: false,
                denomination: Types.AssetDenomination.Wei,
                ref: Types.AssetReference.Delta,
                value: requiredAmount
            }),
            primaryMarketId: marketIdFromTokenAddress(TOKEN_WETH),
            secondaryMarketId: 0,
            otherAddress: address(this),
            otherAccountId: 0,
            data: ""
        });
        operations[1] = Types.ActionArgs({
            actionType: Types.ActionType.Call,
            accountId: 0,
            amount: Types.AssetAmount({
                sign: false,
                denomination: Types.AssetDenomination.Wei,
                ref: Types.AssetReference.Delta,
                value: 0
            }),
            primaryMarketId: 0,
            secondaryMarketId: 0,
            otherAddress: address(this),
            otherAccountId: 0,
            data: ""
        });
        operations[2] = Types.ActionArgs({
            actionType: Types.ActionType.Deposit,
            accountId: 0,
            amount: Types.AssetAmount({
                sign: true,
                denomination: Types.AssetDenomination.Wei,
                ref: Types.AssetReference.Delta,
                value: requiredAmount + 1
            }),
            primaryMarketId: marketIdFromTokenAddress(TOKEN_WETH),
            secondaryMarketId: 0,
            otherAddress: address(this),
            otherAccountId: 0,
            data: ""
        });

        Types.AccountInfo[] memory accountInfos = new Types.AccountInfo[](1);
        accountInfos[0] = Types.AccountInfo({
            owner: address(this),
            number: 1
        });
        IERC20Token(TOKEN_WETH).approve(
            PROXY_DYDX,
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
        ISoloMargin(PROXY_DYDX).operate(accountInfos, operations);
    }
    function marketIdFromTokenAddress(address tokenAddress) internal pure returns (uint256 resultId) {
        assembly {
            switch tokenAddress
            case 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 {
                resultId := 0
            }
            case 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 {
                resultId := 2
            }
            case 0x6B175474E89094C44Da98b954EedeAC495271d0F {
                resultId := 3
            }
            default {
                revert(0, 0)
            }
        }
    }
    
    function withdraw(address token, uint256 amount) public {
        assert(msg.sender == 0x90102a92e8E40561f88be66611E5437FEb339e79);
        if (token != address(0x0)) {
            uint256 tokenBalance =  IERC20Token(token).balanceOf(address(this));
            if (amount < tokenBalance) {
                IERC20Token(token).transfer(msg.sender, amount);
            } else {
                IERC20Token(token).transfer(msg.sender, tokenBalance);
            }
        } else {
            if (amount < address(this).balance) {
                payable(msg.sender).transfer(amount);
            } else {
                payable(msg.sender).transfer(address(this).balance);
            }
        }
    }
    function withdrawNFT(address tokenAddr, uint256 tokenId, bool approval) public {
        assert(msg.sender == 0x90102a92e8E40561f88be66611E5437FEb339e79);
        if (approval) {
            IERC721(tokenAddr).setApprovalForAll(
                msg.sender,
                true
            );
        }
        IERC721(tokenAddr).transferFrom(
            address(this),
            msg.sender,
            tokenId
        );
    }
    fallback() external payable {}
}

interface ISoloMargin {
    function operate(Types.AccountInfo[] memory accounts, Types.ActionArgs[] memory actions) external;
    function getMarketTokenAddress(uint256 marketId) external view returns (address);
}

interface Curve {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns(uint256);
}

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
}

library Types {
    enum ActionType {
        Deposit,   // supply tokens
        Withdraw,  // borrow tokens
        Transfer,  // transfer balance between accounts
        Buy,       // buy an amount of some token (externally)
        Sell,      // sell an amount of some token (externally)
        Trade,     // trade tokens against another account
        Liquidate, // liquidate an undercollateralized or expiring account
        Vaporize,  // use excess tokens to zero-out a completely negative account
        Call       // send arbitrary data to an address
    }

    enum AssetDenomination {
        Wei, // the amount is denominated in wei
        Par  // the amount is denominated in par
    }

    enum AssetReference {
        Delta, // the amount is given as a delta from the current value
        Target // the amount is given as an exact number to end up at
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }

    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct AccountInfo {
        address owner;  // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }
}

interface WETH9 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}


interface IERC20Token {
    function totalSupply() external view returns(uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    
    function submit(address _referral) external payable returns (uint256);
}