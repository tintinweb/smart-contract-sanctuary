/**
 *Submitted for verification at Etherscan.io on 2020-04-19
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface LiqudityInterface {
    function deposit(address, uint) external payable;
    function withdraw(address, uint) external;

    function accessLiquidity(address[] calldata, uint[] calldata) external;
    function returnLiquidity(address[] calldata) external payable;

    function isTknAllowed(address) external view returns(bool);
    function tknToCTkn(address) external view returns(address);
    function liquidityBalance(address, address) external view returns(uint);
}

interface CTokenInterface {
    function borrowBalanceCurrent(address account) external returns (uint);
    function balanceOf(address owner) external view returns (uint256 balance);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint); // For ERC20
}

interface CETHInterface {
    function borrowBalanceCurrent(address account) external returns (uint);
    function repayBorrowBehalf(address borrower) external payable;
}


interface TokenInterface {
    function allowance(address, address) external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
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
        (_type, _id) = (1, 5);
    }
}


contract LiquidityHelpers is Helpers {
    /**
     * @dev Return InstaPool address
     */
    function getLiquidityAddress() internal pure returns (address) {
        return 0x1879BEE186BFfBA9A8b1cAD8181bBFb218A5Aa61;
    }
}


contract LiquidityManage is LiquidityHelpers {

    event LogDepositLiquidity(address indexed token, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogWithdrawLiquidity(address indexed token, uint256 tokenAmt, uint256 getId, uint256 setId);

    /**
     * @dev Deposit Liquidity in InstaPool.
     * @param token token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function deposit(address token, uint amt, uint getId, uint setId) external payable {
        uint _amt = getUint(getId, amt);

        uint ethAmt;
        if (token == getAddressETH()) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            ethAmt = _amt;
        } else {
            _amt = _amt == uint(-1) ? TokenInterface(token).balanceOf(address(this)) : _amt;
            TokenInterface(token).approve(getLiquidityAddress(), _amt);
        }

        LiqudityInterface(getLiquidityAddress()).deposit.value(ethAmt)(token, _amt);
        setUint(setId, _amt);

        emit LogDepositLiquidity(token, _amt, getId, setId);
        bytes32 _eventCode = keccak256("LogDepositLiquidity(address,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, _amt, getId, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

    /**
     * @dev Withdraw Liquidity in InstaPool.
     * @param token token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function withdraw(address token, uint amt, uint getId, uint setId) external payable {
        uint _amt = getUint(getId, amt);

        LiqudityInterface(getLiquidityAddress()).withdraw(token, _amt);
        setUint(setId, _amt);

        emit LogWithdrawLiquidity(token, _amt, getId, setId);
        bytes32 _eventCode = keccak256("LogWithdrawLiquidity(address,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, _amt, getId, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }
}


contract LiquidityAccess is LiquidityManage {
    event LogAccessLiquidity(address indexed token, uint256 tokenAmt, uint256 getId, uint256 setId);
    event LogReturnLiquidity(address indexed token, uint256 tokenAmt, uint256 getId, uint256 setId);

    /**
     * @dev Access Token Liquidity from InstaPool.
     * @param token token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function accessLiquidity(address token, uint amt, uint getId, uint setId) external payable {
        uint _amt = getUint(getId, amt);

        address[] memory _tknAddrs = new address[](1);
        _tknAddrs[0] = token;
        uint[] memory _amts = new uint[](1);
        _amts[0] = _amt;

        LiqudityInterface(getLiquidityAddress()).accessLiquidity(_tknAddrs, _amts);

        setUint(setId, _amt);

        emit LogAccessLiquidity(token, _amt, getId, setId);
        bytes32 _eventCode = keccak256("LogAccessLiquidity(address,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, _amt, getId, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

    /**
     * @dev Return Token Liquidity from InstaPool.
     * @param token token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function returnLiquidity(address token, uint getId, uint setId) external payable {
        LiqudityInterface liquidityContract = LiqudityInterface(getLiquidityAddress());
        uint _amt;

        if (token == getAddressETH()) {
            CETHInterface cethContract = CETHInterface(liquidityContract.tknToCTkn(token));
            _amt = cethContract.borrowBalanceCurrent(address(liquidityContract));
            cethContract.repayBorrowBehalf.value(_amt)(address(liquidityContract));
        } else {
            CTokenInterface ctokenContract = CTokenInterface(liquidityContract.tknToCTkn(token));
            _amt = ctokenContract.borrowBalanceCurrent(address(liquidityContract));
            TokenInterface(token).approve(address(ctokenContract), _amt);
            require(ctokenContract.repayBorrowBehalf(address(liquidityContract), _amt) == 0, "repay-failed");
        }

        setUint(setId, _amt);

        emit LogReturnLiquidity(token, _amt, getId, setId);
        bytes32 _eventCode = keccak256("LogReturnLiquidity(address,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(token, _amt, getId, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

    /**
     * @dev Access Multiple Token liquidity from InstaPool.
     * @param tokens Array of token addresses.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amts Array of token amount.
     * @param getId get token amounts at this IDs from `InstaMemory` Contract.
     * @param setId set token amounts at this IDs in `InstaMemory` Contract.
    */
    function accessMultiLiquidity(
        address[] calldata tokens,
        uint[] calldata amts,
        uint[] calldata getId,
        uint[] calldata setId
    ) external payable {
        uint _length = tokens.length;
        uint[] memory _amts = new uint[](_length);
        for (uint i = 0; i < _length; i++) {
            _amts[i] = getUint(getId[i], amts[i]);
        }

        LiqudityInterface(getLiquidityAddress()).accessLiquidity(tokens, _amts);

        for (uint i = 0; i < _length; i++) {
            setUint(setId[i], _amts[i]);

            emit LogAccessLiquidity(tokens[i], _amts[i], getId[i], setId[i]);
            bytes32 _eventCode = keccak256("LogAccessLiquidity(address,uint256,uint256,uint256)");
            bytes memory _eventParam = abi.encode(tokens[i], _amts[i], getId[i], setId[i]);
            (uint _type, uint _id) = connectorID();
            EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
        }
    }

    /**
     * @dev Return Multiple token liquidity from InstaPool.
     * @param tokens Array of token addresses.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param getId get token amounts at this IDs from `InstaMemory` Contract.
     * @param setId set token amounts at this IDs in `InstaMemory` Contract.
    */
    function returnMultiLiquidity(address[] calldata tokens, uint[] calldata getId, uint[] calldata setId) external payable {
        LiqudityInterface liquidityContract = LiqudityInterface(getLiquidityAddress());

        uint _length = tokens.length;

        for (uint i = 0; i < _length; i++) {

            for (uint j = 0; j < _length; j++) {
                if (tokens[i] == tokens[j] && i != j) require(false, "tkn-repeated");
            }

            uint _amt;

            if (tokens[i] == getAddressETH()) {
                CETHInterface cethContract = CETHInterface(liquidityContract.tknToCTkn(tokens[i]));
                _amt = cethContract.borrowBalanceCurrent(address(liquidityContract));
                cethContract.repayBorrowBehalf.value(_amt)(address(liquidityContract));
            } else {
                CTokenInterface ctokenContract = CTokenInterface(liquidityContract.tknToCTkn(tokens[i]));
                _amt = ctokenContract.borrowBalanceCurrent(address(liquidityContract));
                TokenInterface(tokens[i]).approve(address(ctokenContract), _amt);
                require(ctokenContract.repayBorrowBehalf(address(liquidityContract), _amt) == 0, "repay-failed");
            }

            setUint(setId[i], _amt);

            emit LogReturnLiquidity(tokens[i], _amt, getId[i], setId[i]);
            bytes32 _eventCode = keccak256("LogReturnLiquidity(address,uint256,uint256,uint256)");
            bytes memory _eventParam = abi.encode(tokens[i], _amt, getId[i], setId[i]);
            (uint _type, uint _id) = connectorID();
            EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
        }
    }
}


contract ConnectPool is LiquidityAccess {
    string public name = "InstaPool-v1";
}