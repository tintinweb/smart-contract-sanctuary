pragma solidity ^0.6.0;

interface CrTokenInterface {
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);

    function borrowBalanceCurrent(address account) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);

    function balanceOf(address owner) external view returns (uint256 balance);
}

interface CrETHInterface {
    function mint() external payable;
    function repayBorrow() external payable;
}

interface TokenInterface {
    function allowance(address, address) external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
}

interface ComptrollerInterface {
    function enterMarkets(address[] calldata CrTokens) external returns (uint[] memory);
    function exitMarket(address CrTokenAddress) external returns (uint);
    function getAssetsIn(address account) external view returns (address[] memory);
}

interface InstaCreamMapping {
    function CrTokenMapping(address) external view returns (address);
}

interface MemoryInterface {
    function getUint(uint _id) external returns (uint _num);
    function setUint(uint _id, uint _val) external;
}

interface EventInterface {
    function emitEvent(uint _connectorType, uint _connectorID, bytes32 _eventCode, bytes calldata _eventData) external;
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

    /**
     * @dev Return InstaEvent Address.
     */
    function getEventAddr() internal pure returns (address) {
        return 0x2af7ea6Cb911035f3eb1ED895Cb6692C39ecbA97; // InstaEvent Address
    }

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
        (_type, _id) = (1, 50);
    }
}


contract CreamHelpers is Helpers {
    /**
     * @dev Return Cream Comptroller Address
     */
    function getComptrollerAddress() internal pure returns (address) {
        return 0x3d5BC3c8d13dcB8bF317092d84783c2697AE9258;
    }

    /**
     * @dev Return InstaDApp Mapping Addresses
     */
    function getMappingAddr() internal pure returns (address) {
        return 0x0a9b8a5D1A5FbF939CFD766bC22a018c5595faFe; // InstaCreamMapping Address
    }

    /**
     * @dev enter cream market
     */
    function enterMarket(address CrToken) internal {
        ComptrollerInterface troller = ComptrollerInterface(getComptrollerAddress());
        address[] memory markets = troller.getAssetsIn(address(this));
        bool isEntered = false;
        for (uint i = 0; i < markets.length; i++) {
            if (markets[i] == CrToken) {
                isEntered = true;
            }
        }
        if (!isEntered) {
            address[] memory toEnter = new address[](1);
            toEnter[0] = CrToken;
            troller.enterMarkets(toEnter);
        }
    }
}


contract BasicResolver is CreamHelpers {
    event LogDeposit(address indexed token, address CrToken, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogWithdraw(address indexed token, address CrToken, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogBorrow(address indexed token, address CrToken, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogPayback(address indexed token, address CrToken, uint256 tokenAmt, uint256 getId, uint256 setId);

    /**
     * @dev Deposit ETH/ERC20_Token.
     * @param token token address to deposit.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to deposit.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function deposit(address token, uint amt, uint getId, uint setId) external payable{
        uint _amt = getUint(getId, amt);
        address CrToken = InstaCreamMapping(getMappingAddr()).CrTokenMapping(token);
        enterMarket(CrToken);
        if (token == getAddressETH()) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            CrETHInterface(CrToken).mint.value(_amt)();
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            _amt = _amt == uint(-1) ? tokenContract.balanceOf(address(this)) : _amt;
            tokenContract.approve(CrToken, _amt);
            require(CrTokenInterface(CrToken).mint(_amt) == 0, "minting-failed");
        }
        setUint(setId, _amt);

        emit LogDeposit(token, CrToken, _amt, getId, setId);
        bytes32 _eventCode = keccak256("LogDeposit(address,address,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, CrToken, _amt, getId, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

    /**
     * @dev Withdraw ETH/ERC20_Token.
     * @param token token address to withdraw.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to withdraw.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function withdraw(address token, uint amt, uint getId, uint setId) external payable{
        uint _amt = getUint(getId, amt);
        address CrToken = InstaCreamMapping(getMappingAddr()).CrTokenMapping(token);
        CrTokenInterface CrTokenContract = CrTokenInterface(CrToken);
        if (_amt == uint(-1)) {
            TokenInterface tokenContract = TokenInterface(token);
            uint initialBal = token == getAddressETH() ? address(this).balance : tokenContract.balanceOf(address(this));
            require(CrTokenContract.redeem(CrTokenContract.balanceOf(address(this))) == 0, "full-withdraw-failed");
            uint finalBal = token == getAddressETH() ? address(this).balance : tokenContract.balanceOf(address(this));
            _amt = finalBal - initialBal;
        } else {
            require(CrTokenContract.redeemUnderlying(_amt) == 0, "withdraw-failed");
        }
        setUint(setId, _amt);

        emit LogWithdraw(token, CrToken, _amt, getId, setId);
        bytes32 _eventCode = keccak256("LogWithdraw(address,address,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, CrToken, _amt, getId, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

    /**
     * @dev Borrow ETH/ERC20_Token.
     * @param token token address to borrow.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to borrow.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function borrow(address token, uint amt, uint getId, uint setId) external payable {
        uint _amt = getUint(getId, amt);
        address CrToken = InstaCreamMapping(getMappingAddr()).CrTokenMapping(token);
        enterMarket(CrToken);
        require(CrTokenInterface(CrToken).borrow(_amt) == 0, "borrow-failed");
        setUint(setId, _amt);

        emit LogBorrow(token, CrToken, _amt, getId, setId);
        bytes32 _eventCode = keccak256("LogBorrow(address,address,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, CrToken, _amt, getId, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

    /**
     * @dev Payback borrowed ETH/ERC20_Token.
     * @param token token address to payback.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to payback.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function payback(address token, uint amt, uint getId, uint setId) external payable {
        uint _amt = getUint(getId, amt);
        address CrToken = InstaCreamMapping(getMappingAddr()).CrTokenMapping(token);
        CrTokenInterface CrTokenContract = CrTokenInterface(CrToken);
        _amt = _amt == uint(-1) ? CrTokenContract.borrowBalanceCurrent(address(this)) : _amt;

        if (token == getAddressETH()) {
            require(address(this).balance >= _amt, "not-enough-eth");
            CrETHInterface(CrToken).repayBorrow.value(_amt)();
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            require(tokenContract.balanceOf(address(this)) >= _amt, "not-enough-token");
            tokenContract.approve(CrToken, _amt);
            require(CrTokenContract.repayBorrow(_amt) == 0, "repay-failed.");
        }
        setUint(setId, _amt);

        emit LogPayback(token, CrToken, _amt, getId, setId);
        bytes32 _eventCode = keccak256("LogPayback(address,address,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, CrToken, _amt, getId, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }
}

contract ExtraResolver is BasicResolver {
    event LogDepositCrToken(address indexed token, address CrToken, uint256 tokenAmt, uint256 CrTokenAmt,uint256 getId, uint256 setId);
    event LogWithdrawCrToken(address indexed token, address CrToken, uint256 CrTokenAmt, uint256 getId, uint256 setId);

    /**
     * @dev Deposit ETH/ERC20_Token.
     * @param token token address to depositCrToken.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to depositCrToken.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set CrToken amount at this ID in `InstaMemory` Contract.
    */
    function depositCrToken(address token, uint amt, uint getId, uint setId) external payable{
        uint _amt = getUint(getId, amt);
        address CrToken = InstaCreamMapping(getMappingAddr()).CrTokenMapping(token);
        enterMarket(CrToken);

        CrTokenInterface CrTokenContract = CrTokenInterface(CrToken);
        uint initialBal = CrTokenContract.balanceOf(address(this));

        if (token == getAddressETH()) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            CrETHInterface(CrToken).mint.value(_amt)();
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            _amt = _amt == uint(-1) ? tokenContract.balanceOf(address(this)) : _amt;
            tokenContract.approve(CrToken, _amt);
            require(CrTokenContract.mint(_amt) == 0, "deposit-CrToken-failed.");
        }

        uint finalBal = CrTokenContract.balanceOf(address(this));
        uint _cAmt = finalBal - initialBal;
        setUint(setId, _cAmt);

        emit LogDepositCrToken(token, CrToken, _amt, _cAmt, getId, setId);
        bytes32 _eventCode = keccak256("LogDepositCrToken(address,address,uint256,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, CrToken, _amt, _cAmt, getId, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

    /**
     * @dev Withdraw CrETH/CrERC20_Token using CrToken Amt.
     * @param token token address to withdraw CrToken.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param CrTokenAmt CrToken amount to withdrawCrToken.
     * @param getId Get CrToken amount at this ID from `InstaMemory` Contract.
     * @param setId Set CrToken amount at this ID in `InstaMemory` Contract.
    */
    function withdrawCrToken(address token, uint CrTokenAmt, uint getId, uint setId) external payable {
        uint _amt = getUint(getId, CrTokenAmt);
        address CrToken = InstaCreamMapping(getMappingAddr()).CrTokenMapping(token);
        CrTokenInterface CrTokenContract = CrTokenInterface(CrToken);
        _amt = _amt == uint(-1) ? CrTokenContract.balanceOf(address(this)) : _amt;
        require(CrTokenContract.redeem(_amt) == 0, "redeem-failed");
        setUint(setId, _amt);

        emit LogWithdrawCrToken(token, CrToken, _amt, getId, setId);
        bytes32 _eventCode = keccak256("LogWithdrawCrToken(address,address,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, CrToken, _amt, getId, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);

    }
}


contract ConnectCreamFinance is ExtraResolver {
    string constant public name = "Cream-finance-v1.0";
}