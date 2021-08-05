/**
 *Submitted for verification at Etherscan.io on 2020-07-11
*/

pragma solidity ^0.6.0;

interface TokenInterface {
    function allowance(address, address) external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
}

interface ComptrollerInterface {
    function claimComp(address holder) external;
    function claimComp(address holder, address[] calldata) external;
    function claimComp(address[] calldata holders, address[] calldata cTokens, bool borrowers, bool suppliers) external;
}

interface COMPInterface {
    function delegate(address delegatee) external;
    function delegates(address) external view returns(address);
}

interface InstaMapping {
    function cTokenMapping(address) external view returns (address);
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
        (_type, _id) = (1, 31);
    }
}


contract COMPHelpers is Helpers {
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
        return 0xe81F70Cc7C0D46e12d70efc60607F16bbD617E88; // InstaMapping Address
    }

    function mergeTokenArr(address[] memory supplyTokens, address[] memory borrowTokens)
        internal
        view
        returns (address[] memory ctokens, bool isBorrow, bool isSupply)
    {
        uint _supplyLen = supplyTokens.length;
        uint _borrowLen = borrowTokens.length;
        uint _totalLen = add(_supplyLen, _borrowLen);
        ctokens = new address[](_totalLen);
        isBorrow;
        isSupply;
        if(_supplyLen > 0) {
            for (uint i = 0; i < _supplyLen; i++) {
                ctokens[i] = InstaMapping(getMappingAddr()).cTokenMapping(supplyTokens[i]);
            }
            isSupply = true;
        }

        if(_borrowLen > 0) {
            for (uint i = 0; i < _borrowLen; i++) {
                ctokens[_supplyLen + i] = InstaMapping(getMappingAddr()).cTokenMapping(borrowTokens[i]);
            }
            isBorrow = true;
        }
    }
}


contract BasicResolver is COMPHelpers {
    event LogClaimedComp(uint256 compAmt, uint256 setId);
    event LogDelegate(address delegatee);

    /**
     * @dev Claim Accrued COMP Token.
     * @param setId Set ctoken amount at this ID in `InstaMemory` Contract.
    */
    function ClaimComp(uint setId) external payable {
        TokenInterface compToken = TokenInterface(getCompTokenAddress());
        uint intialBal = compToken.balanceOf(address(this));
        ComptrollerInterface(getComptrollerAddress()).claimComp(address(this));
        uint finalBal = compToken.balanceOf(address(this));
        uint amt = sub(finalBal, intialBal);

        setUint(setId, amt);

        emit LogClaimedComp(amt, setId);
        bytes32 _eventCode = keccak256("LogClaimedComp(uint256,uint256)");
        bytes memory _eventParam = abi.encode(amt, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

    /**
     * @dev Claim Accrued COMP Token.
     * @param tokens Array of tokens supplied and borrowed.
     * @param setId Set ctoken amount at this ID in `InstaMemory` Contract.
    */
    function ClaimCompTwo(address[] calldata tokens, uint setId) external payable {
        uint _len = tokens.length;
        address[] memory ctokens = new address[](_len);
        for (uint i = 0; i < _len; i++) {
            ctokens[i] = InstaMapping(getMappingAddr()).cTokenMapping(tokens[i]);
        }

        TokenInterface compToken = TokenInterface(getCompTokenAddress());
        uint intialBal = compToken.balanceOf(address(this));
        ComptrollerInterface(getComptrollerAddress()).claimComp(address(this), ctokens);
        uint finalBal = compToken.balanceOf(address(this));
        uint amt = sub(finalBal, intialBal);

        setUint(setId, amt);

        emit LogClaimedComp(amt, setId);
        bytes32 _eventCode = keccak256("LogClaimedComp(uint256,uint256)");
        bytes memory _eventParam = abi.encode(amt, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

    /**
     * @dev Claim Accrued COMP Token.
     * @param supplyTokens Array of tokens supplied.
     * @param borrowTokens Array of tokens borrowed.
     * @param setId Set ctoken amount at this ID in `InstaMemory` Contract.
    */
    function ClaimCompThree(address[] calldata supplyTokens, address[] calldata borrowTokens, uint setId) external payable {
       (address[] memory ctokens, bool isBorrow, bool isSupply) = mergeTokenArr(supplyTokens, borrowTokens);

        address[] memory holders = new address[](1);
        holders[0] = address(this);

        TokenInterface compToken = TokenInterface(getCompTokenAddress());
        uint intialBal = compToken.balanceOf(address(this));
        ComptrollerInterface(getComptrollerAddress()).claimComp(holders, ctokens, isBorrow, isSupply);
        uint finalBal = compToken.balanceOf(address(this));
        uint amt = sub(finalBal, intialBal);

        setUint(setId, amt);

        emit LogClaimedComp(amt, setId);
        bytes32 _eventCode = keccak256("LogClaimedComp(uint256,uint256)");
        bytes memory _eventParam = abi.encode(amt, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

    /**
     * @dev Delegate votes.
     * @param delegatee The address to delegate votes to.
    */
    function delegate(address delegatee) external payable {
        COMPInterface compToken = COMPInterface(getCompTokenAddress());
        require(compToken.delegates(address(this)) != delegatee, "Already delegated to same delegatee.");

        compToken.delegate(delegatee);

        emit LogDelegate(delegatee);
        bytes32 _eventCode = keccak256("LogDelegate(address)");
        bytes memory _eventParam = abi.encode(delegatee);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }
}

contract ConnectCOMP is BasicResolver {
    string public name = "COMP-v1";
}