/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

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

interface InstaCompoundMapping {
    function getMapping(string calldata tokenId) external view returns (address, address);
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
     * @dev Connector Details.
     */
    function connectorID() public pure returns(uint model, uint id) {
        (model, id) = (1, 88);
    }

    // /**
    //  * @dev emit event on event contract
    //  */
    // function emitEvent(bytes32 eventCode, bytes memory eventData) internal {
    //     (uint model, uint id) = connectorID();
    //     EventInterface(getEventAddr()).emitEvent(model, id, eventCode, eventData);
    // }
}

contract ImportHelper is Helpers {
    /**
     * @dev Return InstaDApp Mapping Address
     */
    function getMappingAddr() internal pure returns (address) {
        return 0xA8F9D4aA7319C54C04404765117ddBf9448E2082; // InstaCompoundMapping Address
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
    function enterMarkets(address[] memory cErc20) internal {
        ComptrollerInterface(getComptrollerAddress()).enterMarkets(cErc20);
    }
}

contract ImportResolver is ImportHelper {

    event LogCompoundImport(
        address user,
        address[] cTokens,
        uint[] cTknBals,
        uint[] borrowBals
    );

    function _borrow(CTokenInterface[] memory ctokenContracts, uint[] memory amts, uint _length) internal {
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                require(ctokenContracts[i].borrow(amts[i]) == 0, "borrow-failed-collateral?");
            }
        }
    }

    function _paybackOnBehalf(
        address userAddress,
        CTokenInterface[] memory ctokenContracts,
        uint[] memory amts,
        uint _length
    ) internal {
        address cethAddr = getCETHAddr();
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                if (address(ctokenContracts[i]) == cethAddr) {
                     CETHInterface(cethAddr).repayBorrowBehalf.value(amts[i])(userAddress);
                } else {
                    require(ctokenContracts[i].repayBorrowBehalf(userAddress, amts[i]) == 0, "repayOnBehalf-failed");
                }
            }
        }
    }

    function _transferCtokens(
        address userAccount,
        CTokenInterface[] memory ctokenContracts,
        uint[] memory amts,
        uint _length
    ) internal {
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                require(ctokenContracts[i].transferFrom(userAccount, address(this), amts[i]), "ctoken-transfer-failed-allowance?");
            }
        }
    }

    function importCompound(address userAccount, string[] calldata tokenIds) external payable {
        require(DSAInterface(address(this)).isAuth(userAccount), "user-account-not-auth");

        uint _length = tokenIds.length;
        require(_length > 0, "0-tokens-not-allowed");


        address[] memory ctokens = new address[](_length);
        uint[] memory borrowAmts = new uint[](_length);
        uint[] memory ctokensBal = new uint[](_length);
        CTokenInterface[] memory ctokenContracts = new CTokenInterface[](_length);

        InstaCompoundMapping compMapping = InstaCompoundMapping(getMappingAddr());

        for (uint i = 0; i < _length; i++) {
            (address _token, address _ctoken) = compMapping.getMapping(tokenIds[i]);
            require(_token != address(0) && _ctoken != address(0), "ctoken mapping not found");

            ctokens[i] = _ctoken;

            ctokenContracts[i] = CTokenInterface(ctokens[i]);

            ctokensBal[i] = ctokenContracts[i].balanceOf(userAccount);
            borrowAmts[i] = ctokenContracts[i].borrowBalanceCurrent(userAccount);
            if (_token != getAddressETH() && borrowAmts[i] > 0) {
                TokenInterface(_token).approve(ctokens[i], borrowAmts[i]);
            }
        }

        enterMarkets(ctokens);
        _borrow(ctokenContracts, borrowAmts, _length);
        _paybackOnBehalf(userAccount, ctokenContracts, borrowAmts, _length);
        _transferCtokens(userAccount, ctokenContracts, ctokensBal, _length);

        emit LogCompoundImport(userAccount, ctokens, ctokensBal, borrowAmts);
    }
}

contract ConnectCompoundImport is ImportResolver {
    string public name = "Compound-Import-v2.1";
}