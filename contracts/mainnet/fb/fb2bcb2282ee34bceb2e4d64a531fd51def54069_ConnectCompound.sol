/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface CTokenInterface {
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint); // For ERC20
    function liquidateBorrow(address borrower, uint repayAmount, address cTokenCollateral) external returns (uint);

    function borrowBalanceCurrent(address account) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function exchangeRateCurrent() external returns (uint);

    function balanceOf(address owner) external view returns (uint256 balance);
}

interface CETHInterface {
    function mint() external payable;
    function repayBorrow() external payable;
    function repayBorrowBehalf(address borrower) external payable;
    function liquidateBorrow(address borrower, address cTokenCollateral) external payable;
}

interface TokenInterface {
    function allowance(address, address) external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
}

interface ComptrollerInterface {
    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function exitMarket(address cTokenAddress) external returns (uint);
    function getAssetsIn(address account) external view returns (address[] memory);
    function getAccountLiquidity(address account) external view returns (uint, uint, uint);
    function claimComp(address) external;
}

interface InstaMappingV2 {
    function getMapping(string calldata tokenId) external view returns (address, address);
}

interface MemoryInterface {
    function getUint(uint _id) external returns (uint _num);
    function setUint(uint _id, uint _val) external;
}

contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    uint constant WAD = 10 ** 18;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

}


contract Helpers is DSMath {
    /**
     * @dev Return ethereum address
     */
    function getAddressETH() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH Address
    }

    /**
     * @dev Return Memory Variable Address
     */
    function getMemoryAddr() internal pure returns (address) {
        return 0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F; // InstaMemory Address
    }

    // /**
    //  * @dev Return InstaEvent Address.
    //  */
    // function getEventAddr() internal pure returns (address) {
    //     return 0x2af7ea6Cb911035f3eb1ED895Cb6692C39ecbA97; // InstaEvent Address
    // }

    /**
     * @dev Get Uint value from InstaMemory Contract.
    */
    function getUint(uint getId, uint val) internal returns (uint returnVal) {
        returnVal = getId == 0 ? val : MemoryInterface(getMemoryAddr()).getUint(getId);
    }

    /**
     * @dev Set Uint value in InstaMemory Contract.
    */
    function setUint(uint setId, uint val) internal {
        if (setId != 0) MemoryInterface(getMemoryAddr()).setUint(setId, val);
    }

    /**
     * @dev Connector Details
    */
    function connectorID() public pure returns(uint _type, uint _id) {
        (_type, _id) = (1, 57);
    }
}


contract CompoundHelpers is Helpers {
    /**
     * @dev Return Compound Comptroller Address
     */
    function getComptrollerAddress() internal pure returns (address) {
        return 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    }

    /**
     * @dev Return COMP Token Address.
     */
    function getCompTokenAddress() internal pure returns (address) {
        return 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    }

    /**
     * @dev Return InstaDApp Mapping Addresses
     */
    function getMappingAddr() internal pure returns (address) {
        return 0xA8F9D4aA7319C54C04404765117ddBf9448E2082; // InstaMapping Address
    }

    /**
     * @dev enter compound market
     */
    function enterMarket(address cToken) internal {
        ComptrollerInterface troller = ComptrollerInterface(getComptrollerAddress());
        address[] memory markets = troller.getAssetsIn(address(this));
        bool isEntered = false;
        for (uint i = 0; i < markets.length; i++) {
            if (markets[i] == cToken) {
                isEntered = true;
            }
        }
        if (!isEntered) {
            address[] memory toEnter = new address[](1);
            toEnter[0] = cToken;
            troller.enterMarkets(toEnter);
        }
    }
}


contract BasicResolver is CompoundHelpers {
    event LogDeposit(address indexed token, string tokenId, address cToken, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogWithdraw(address indexed token, string tokenId, address cToken, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogBorrow(address indexed token, string tokenId, address cToken, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogPayback(address indexed token, string tokenId, address cToken, uint256 tokenAmt, uint256 getId, uint256 setId);

    /**
     * @dev Deposit ETH/ERC20_Token.
     * @param tokenId token id of the token to deposit.(For eg: ETH-A)
     * @param amt token amount to deposit.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function deposit(string calldata tokenId, uint amt, uint getId, uint setId) external payable{
        uint _amt = getUint(getId, amt);
        (address token, address cToken) = InstaMappingV2(getMappingAddr()).getMapping(tokenId);
        require(token != address(0) && cToken != address(0), "ctoken mapping not found");
        enterMarket(cToken);
        if (token == getAddressETH()) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            CETHInterface(cToken).mint.value(_amt)();
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            _amt = _amt == uint(-1) ? tokenContract.balanceOf(address(this)) : _amt;
            tokenContract.approve(cToken, _amt);
            require(CTokenInterface(cToken).mint(_amt) == 0, "deposit-failed");
        }
        setUint(setId, _amt);

        emit LogDeposit(token, tokenId, cToken, _amt, getId, setId);
    }

    /**
     * @dev Withdraw ETH/ERC20_Token.
     * @param tokenId token id of the token to withdraw.(For eg: ETH-A)
     * @param amt token amount to withdraw.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function withdraw(string calldata tokenId, uint amt, uint getId, uint setId) external payable{
        uint _amt = getUint(getId, amt);
        (address token, address cToken) = InstaMappingV2(getMappingAddr()).getMapping(tokenId);
        require(token != address(0) && cToken != address(0), "ctoken mapping not found");
        CTokenInterface cTokenContract = CTokenInterface(cToken);
        if (_amt == uint(-1)) {
            TokenInterface tokenContract = TokenInterface(token);
            uint initialBal = token == getAddressETH() ? address(this).balance : tokenContract.balanceOf(address(this));
            require(cTokenContract.redeem(cTokenContract.balanceOf(address(this))) == 0, "full-withdraw-failed");
            uint finalBal = token == getAddressETH() ? address(this).balance : tokenContract.balanceOf(address(this));
            _amt = finalBal - initialBal;
        } else {
            require(cTokenContract.redeemUnderlying(_amt) == 0, "withdraw-failed");
        }
        setUint(setId, _amt);

        emit LogWithdraw(token, tokenId, cToken, _amt, getId, setId);
    }

    /**
     * @dev Borrow ETH/ERC20_Token.
     * @param tokenId token id of the token to borrow.(For eg: DAI-A)
     * @param amt token amount to borrow.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function borrow(string calldata tokenId, uint amt, uint getId, uint setId) external payable {
        uint _amt = getUint(getId, amt);
        (address token, address cToken) = InstaMappingV2(getMappingAddr()).getMapping(tokenId);
        require(token != address(0) && cToken != address(0), "ctoken mapping not found");
        enterMarket(cToken);
        require(CTokenInterface(cToken).borrow(_amt) == 0, "borrow-failed");
        setUint(setId, _amt);

        emit LogBorrow(token, tokenId, cToken, _amt, getId, setId);
    }

    /**
     * @dev Payback borrowed ETH/ERC20_Token.
     * @param tokenId token id of the token to payback.(For eg: COMP-A)
     * @param amt token amount to payback.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function payback(string calldata tokenId, uint amt, uint getId, uint setId) external payable {
        uint _amt = getUint(getId, amt);
        (address token, address cToken) = InstaMappingV2(getMappingAddr()).getMapping(tokenId);
        require(token != address(0) && cToken != address(0), "ctoken mapping not found");
        CTokenInterface cTokenContract = CTokenInterface(cToken);
        _amt = _amt == uint(-1) ? cTokenContract.borrowBalanceCurrent(address(this)) : _amt;

        if (token == getAddressETH()) {
            require(address(this).balance >= _amt, "not-enough-eth");
            CETHInterface(cToken).repayBorrow.value(_amt)();
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            require(tokenContract.balanceOf(address(this)) >= _amt, "not-enough-token");
            tokenContract.approve(cToken, _amt);
            require(cTokenContract.repayBorrow(_amt) == 0, "repay-failed.");
        }
        setUint(setId, _amt);

        emit LogPayback(token, tokenId, cToken, _amt, getId, setId);
    }
}

contract ExtraResolver is BasicResolver {
    event LogClaimedComp(uint256 compAmt, uint256 setId);
    event LogDepositCToken(
        address indexed token,
        string tokenId,
        address cToken,
        uint256 tokenAmt,
        uint256 cTokenAmt,
        uint256 getId,
        uint256 setId
    );
    event LogWithdrawCToken(
        address indexed token,
        string tokenId,
        address cToken,
        uint256 tokenAmt,
        uint256 cTokenAmt,
        uint256 getId,
        uint256 setId
    );
    event LogLiquidate(
        address indexed borrower,
        address indexed tokenToPay,
        address indexed tokenInReturn,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );

    struct LiquidateData {
        address tokenToPay;
        address tokenInReturn;
        address cTokenPay;
        address cTokenColl;
}

    /**
     * @dev Deposit ETH/ERC20_Token.
     * @param tokenId token id of the token to depositCToken.(For eg: DAI-A)
     * @param amt token amount to depositCToken.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set ctoken amount at this ID in `InstaMemory` Contract.
    */
    function depositCToken(string calldata tokenId, uint amt, uint getId, uint setId) external payable{
        uint _amt = getUint(getId, amt);
        (address token, address cToken) = InstaMappingV2(getMappingAddr()).getMapping(tokenId);
        require(token != address(0) && cToken != address(0), "ctoken mapping not found");
        enterMarket(cToken);

        CTokenInterface ctokenContract = CTokenInterface(cToken);
        uint initialBal = ctokenContract.balanceOf(address(this));

        if (token == getAddressETH()) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            CETHInterface(cToken).mint.value(_amt)();
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            _amt = _amt == uint(-1) ? tokenContract.balanceOf(address(this)) : _amt;
            tokenContract.approve(cToken, _amt);
            require(ctokenContract.mint(_amt) == 0, "deposit-ctoken-failed.");
        }

        uint finalBal = ctokenContract.balanceOf(address(this));
        uint _cAmt = finalBal - initialBal;
        setUint(setId, _cAmt);

        emit LogDepositCToken(token, tokenId, cToken, _amt, _cAmt, getId, setId);
    }

    /**
     * @dev Withdraw CETH/CERC20_Token using cToken Amt.
     * @param tokenId token id of the token to withdraw CToken.(For eg: ETH-A)
     * @param cTokenAmt ctoken amount to withdrawCToken.
     * @param getId Get ctoken amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function withdrawCToken(string calldata tokenId, uint cTokenAmt, uint getId, uint setId) external payable {
        uint _cAmt = getUint(getId, cTokenAmt);
        (address token, address cToken) = InstaMappingV2(getMappingAddr()).getMapping(tokenId);
        require(token != address(0) && cToken != address(0), "ctoken mapping not found");
        CTokenInterface cTokenContract = CTokenInterface(cToken);
        TokenInterface tokenContract = TokenInterface(token);
        _cAmt = _cAmt == uint(-1) ? cTokenContract.balanceOf(address(this)) : _cAmt;

        uint withdrawAmt;

        {
            uint initialBal = token != getAddressETH() ? tokenContract.balanceOf(address(this)) : address(this).balance;
            require(cTokenContract.redeem(_cAmt) == 0, "redeem-failed");
            uint finalBal = token != getAddressETH() ? tokenContract.balanceOf(address(this)) : address(this).balance;

            withdrawAmt = sub(finalBal, initialBal);
        }

        setUint(setId, withdrawAmt);

        emit LogWithdrawCToken(token, tokenId, cToken, withdrawAmt, _cAmt, getId, setId);
    }

    /**
     * @dev Liquidate a position.
     * @param borrower Borrower's Address.
     * @param tokenIdToPay token id of the token to pay for liquidation.(For eg: ETH-A)
     * @param tokenIdInReturn token id of the token to return for liquidation.(For eg: USDC-A)
     * @param amt token amount to pay for liquidation.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function liquidate(
        address borrower,
        string calldata tokenIdToPay,
        string calldata tokenIdInReturn,
        uint amt,
        uint getId,
        uint setId
    ) external payable
    {
        uint _amt = getUint(getId, amt);

        LiquidateData memory data;

        (data.tokenToPay, data.cTokenPay) = InstaMappingV2(getMappingAddr()).getMapping(tokenIdToPay);
        require(data.tokenToPay != address(0) && data.cTokenPay != address(0), "ctoken mapping not found");
        (data.tokenInReturn, data.cTokenColl) = InstaMappingV2(getMappingAddr()).getMapping(tokenIdInReturn);
        require(data.tokenInReturn != address(0) && data.cTokenColl != address(0), "ctoken mapping not found");
        CTokenInterface cTokenContract = CTokenInterface(data.cTokenPay);

        {
            (,, uint shortfal) = ComptrollerInterface(getComptrollerAddress()).getAccountLiquidity(borrower);
            require(shortfal != 0, "account-cannot-be-liquidated");
        }

        _amt = _amt == uint(-1) ? cTokenContract.borrowBalanceCurrent(borrower) : _amt;
        if (data.tokenToPay == getAddressETH()) {
            require(address(this).balance >= _amt, "not-enought-eth");
            CETHInterface(data.cTokenPay).liquidateBorrow.value(_amt)(borrower, data.cTokenColl);
        } else {
            TokenInterface tokenContract = TokenInterface(data.tokenToPay);
            require(tokenContract.balanceOf(address(this)) >= _amt, "not-enough-token");
            tokenContract.approve(data.cTokenPay, _amt);
            require(cTokenContract.liquidateBorrow(borrower, _amt, data.cTokenColl) == 0, "liquidate-failed");
        }
        setUint(setId, _amt);

        emit LogLiquidate(
            address(this),
            data.tokenToPay,
            data.tokenInReturn,
            _amt,
            getId,
            setId
        );
    }
}


contract ConnectCompound is ExtraResolver {
    string public name = "Compound-v1.4";
}