pragma solidity ^0.6.0;

interface MemoryInterface {
    function getUint(uint _id) external returns (uint _num);
    function setUint(uint _id, uint _val) external;
}

interface EventInterface {
    function emitEvent(uint connectorType, uint connectorID, bytes32 eventCode, bytes calldata eventData) external;
}

interface TokenInterface {
    function balanceOf(address) external view returns (uint);
    function allowance(address, address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
}

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
    function transferFrom(address, address, uint) external returns (bool);
}

interface CETHInterface {
    function mint() external payable;
    function repayBorrow() external payable;
    function repayBorrowBehalf(address borrower) external payable;
    function liquidateBorrow(address borrower, address cTokenCollateral) external payable;
}

interface InstaMapping {
    function cTokenMapping(address) external view returns (address);
}

interface ComptrollerInterface {
    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function exitMarket(address cTokenAddress) external returns (uint);
    function getAssetsIn(address account) external view returns (address[] memory);
    function getAccountLiquidity(address account) external view returns (uint, uint, uint);
}

interface DSAInterface {
    function isAuth(address) external view returns(bool);
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
     * @dev Return InstaEvent Address.
     */
    function getEventAddr() internal pure returns (address) {
        return 0x2af7ea6Cb911035f3eb1ED895Cb6692C39ecbA97; // InstaEvent Address
    }

    /**
     * @dev Return Memory Variable Address
     */
    function getMemoryAddr() internal pure returns (address) {
        return 0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F; // InstaMemory Address
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
     * @dev emit event on event contract
     */
    function emitEvent(bytes32 eventCode, bytes memory eventData) internal {
        (uint model, uint id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(model, id, eventCode, eventData);
    }

    /**
     * @dev Connector Details.
     */
    function connectorID() public pure returns(uint model, uint id) {
        (model, id) = (1, 49);
    }
}

contract ImportHelper is Helpers {
    /**
     * @dev Return InstaDApp Mapping Address
     */
    function getMappingAddr() internal pure returns (address) {
        return 0xe81F70Cc7C0D46e12d70efc60607F16bbD617E88; // InstaMapping Address
    }

    /**
     * @dev Return CETH Address
     */
    function getCETHAddr() internal pure returns (address) {
        return 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    }

    /**
     * @dev Return Compound Comptroller Address
     */
    function getComptrollerAddress() internal pure returns (address) {
        return 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    }

   /**
     * @dev enter compound market
     */
    function enterMarket(address[] memory cErc20) internal {
        ComptrollerInterface(getComptrollerAddress()).enterMarkets(cErc20);
    }
}

contract ImportResolver is ImportHelper {
    event LogImport(
        address user,
        uint times,
        address[] cTokens,
        uint[] cTknBals,
        uint[] borrowBals
    );

    event LogImportPayback(
        address user,
        address token,
        uint amt,
        uint getId,
        uint setId
    );

    function ctokenImport(address userAccount, CTokenInterface[] memory ctokenContracts, uint[] memory amts) private {
        for (uint i = 0; i < ctokenContracts.length; i++) {
            if (amts[i] > 0){
                require(ctokenContracts[i].transferFrom(userAccount, address(this), amts[i]), "allowance?");
            }
        }
    }

    function ctokenBorrowPaybackBehalf(address userAccount, CTokenInterface[] memory ctokenContracts, uint[] memory amts) private {
        for (uint i = 0; i < ctokenContracts.length; i++) {
            if (amts[i] > 0) {
                require(CTokenInterface(ctokenContracts[i]).borrow(amts[i]) == 0, "enough-supply?");
                getCETHAddr() != address(ctokenContracts[i]) ?
                    require(CTokenInterface(ctokenContracts[i]).repayBorrowBehalf(userAccount, amts[i]) == 0, "borrowed?-balance?") :
                    CETHInterface(address(ctokenContracts[i])).repayBorrowBehalf.value(amts[i])(userAccount);
            }
        }
    }

    function _import(
        address userAccount,
        CTokenInterface[] memory ctokenContracts,
        uint[] memory splitBorrowAmts,
        uint[] memory splitCtokensBal,
        uint[] memory borrowAmts,
        uint[] memory ctokensBal,
        uint _length,
        uint _times
    ) internal {
        for (uint i = 0; i < _times; i++) {
            if (i < _times - 1) {
                ctokenBorrowPaybackBehalf(userAccount, ctokenContracts, splitBorrowAmts);
                ctokenImport(userAccount, ctokenContracts, splitCtokensBal);
            } else {
                uint[] memory _borrowAmts = new uint[](_length);
                uint[] memory _ctokensBal = new uint[](_length);
                for (uint j = 0; j < _length; j++) {
                    _borrowAmts[j] = borrowAmts[j] > 0 ?
                        ctokenContracts[j].borrowBalanceCurrent(userAccount) : 0;
                    _ctokensBal[j] = ctokensBal[j] > 0 ?
                        ctokenContracts[j].balanceOf(userAccount): 0;
                }
                ctokenBorrowPaybackBehalf(userAccount, ctokenContracts, _borrowAmts);
                ctokenImport(userAccount, ctokenContracts, _ctokensBal);
            }
        }
    }

    /**
     * @dev Import Compound Position.
    */
    function importCompound(
        address userAccount,
        address[] calldata tokens,
        uint times
    )
        external
        payable
    {   
        require(DSAInterface(address(this)).isAuth(userAccount), "user-account-not-auth");

        uint _length = tokens.length;
        require(times > 0 && _length > 0, "times-0-or-length-0");
        address[] memory ctokens = new address[](_length);
        uint[] memory borrowAmts = new uint[](_length);
        uint[] memory splitBorrowAmts = new uint[](_length);
        uint[] memory ctokensBal = new uint[](_length);
        uint[] memory splitCtokensBal = new uint[](_length);

        CTokenInterface[] memory ctokenContracts = new CTokenInterface[](_length);
        InstaMapping instaMap = InstaMapping(getMappingAddr());
        for (uint i = 0; i < _length; i++) {
            ctokens[i] = instaMap.cTokenMapping(tokens[i]);
            require(ctokens[i] != address(0), "adderss-0");
            ctokenContracts[i] = CTokenInterface(ctokens[i]);
            ctokensBal[i] = ctokenContracts[i].balanceOf(userAccount);
            splitCtokensBal[i] = ctokensBal[i] / times;
            if (times != 1) {
                borrowAmts[i] = ctokenContracts[i].borrowBalanceCurrent(userAccount);
                if (ctokens[i] != getCETHAddr()) TokenInterface(tokens[i]).approve(ctokens[i], borrowAmts[i]);
                splitBorrowAmts[i] = borrowAmts[i] / (times - 1);
            }
        }

        enterMarket(ctokens);
        times == 1 ? ctokenImport(userAccount, ctokenContracts, ctokensBal) : ctokenImport(userAccount, ctokenContracts, splitCtokensBal);

        uint _times = times - 1;
        _import(
            userAccount,
            ctokenContracts,
            splitBorrowAmts,
            splitCtokensBal,
            borrowAmts,
            ctokensBal,
            _length,
            _times
        );

        emit LogImport(userAccount, times, ctokens, ctokensBal, borrowAmts);
        bytes32 _eventCode = keccak256("LogImport(address,uint256,address[],uint256[],uint256[])");
        bytes memory _eventParam = abi.encode(userAccount, times, ctokens, ctokensBal, borrowAmts);
        emitEvent(_eventCode, _eventParam);
    }

    /**
     * @dev Payback User Account Compound Debt
    */
    function importPaybackBehalf(
        address userAccount,
        address token,
        uint amt,
        uint getId,
        uint setId
    ) external payable {
        require(DSAInterface(address(this)).isAuth(userAccount), "user-account-not-auth");

        uint _amt = getUint(getId, amt);
        if (amt > 0) {
            InstaMapping instaMap = InstaMapping(getMappingAddr());
            address cToken = instaMap.cTokenMapping(token);
            CTokenInterface ctokenContract = CTokenInterface(cToken);
            require(cToken != address(0), "adderss-0");
            _amt = amt == uint(-1) ?
                ctokenContract.borrowBalanceCurrent(userAccount) : amt;
            if (cToken != getCETHAddr()) {
                TokenInterface(token).approve(cToken, _amt);
                require(ctokenContract.repayBorrowBehalf(userAccount, _amt) == 0, "borrowed?-balance?");
            } else {
                CETHInterface(cToken).repayBorrowBehalf.value(_amt)(userAccount);
            }
        }
        setUint(setId, _amt);

        emit LogImportPayback(userAccount, token, _amt, getId, setId);
        bytes32 _eventCode = keccak256("LogImportPayback(address,address,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(userAccount, token, _amt, getId, setId);
        emitEvent(_eventCode, _eventParam);
    }

}

contract ConnectCompoundImport is ImportResolver {
    string public name = "Compound-Import-v1.2";
}