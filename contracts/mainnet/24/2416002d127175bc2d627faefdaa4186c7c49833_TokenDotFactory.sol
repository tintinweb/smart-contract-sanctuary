pragma solidity ^0.4.24;

// File: contracts/lib/ownership/Ownable.sol

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);

    /// @dev The Ownable constructor sets the original `owner` of the contract to the sender account.
    constructor() public { owner = msg.sender; }

    /// @dev Throws if called by any contract other than latest designated caller
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /// @dev Allows the current owner to transfer control of the contract to a newOwner.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(address newOwner) public onlyOwner {
       require(newOwner != address(0));
       emit OwnershipTransferred(owner, newOwner);
       owner = newOwner;
    }
}

// File: contracts/lib/token/FactoryTokenInterface.sol

contract FactoryTokenInterface is Ownable {
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function mint(address _to, uint256 _amount) public returns (bool);
    function burnFrom(address _from, uint256 _value) public;
}

// File: contracts/lib/token/TokenFactoryInterface.sol

contract TokenFactoryInterface {
    function create(string _name, string _symbol) public returns (FactoryTokenInterface);
}

// File: contracts/lib/ownership/ZapCoordinatorInterface.sol

contract ZapCoordinatorInterface is Ownable {
	function addImmutableContract(string contractName, address newAddress) external;
	function updateContract(string contractName, address newAddress) external;
	function getContractName(uint index) public view returns (string);
	function getContract(string contractName) public view returns (address);
	function updateAllDependencies() external;
}

// File: contracts/platform/bondage/BondageInterface.sol

contract BondageInterface {
    function bond(address, bytes32, uint256) external returns(uint256);
    function unbond(address, bytes32, uint256) external returns (uint256);
    function delegateBond(address, address, bytes32, uint256) external returns(uint256);
    function escrowDots(address, address, bytes32, uint256) external returns (bool);
    function releaseDots(address, address, bytes32, uint256) external returns (bool);
    function returnDots(address, address, bytes32, uint256) external returns (bool success);
    function calcZapForDots(address, bytes32, uint256) external view returns (uint256);
    function currentCostOfDot(address, bytes32, uint256) public view returns (uint256);
    function getDotsIssued(address, bytes32) public view returns (uint256);
    function getBoundDots(address, address, bytes32) public view returns (uint256);
    function getZapBound(address, bytes32) public view returns (uint256);
    function dotLimit( address, bytes32) public view returns (uint256);
}

// File: contracts/platform/bondage/currentCost/CurrentCostInterface.sol

contract CurrentCostInterface {    
    function _currentCostOfDot(address, bytes32, uint256) public view returns (uint256);
    function _dotLimit(address, bytes32) public view returns (uint256);
    function _costOfNDots(address, bytes32, uint256, uint256) public view returns (uint256);
}

// File: contracts/platform/registry/RegistryInterface.sol

// Technically an abstract contract, not interface (solidity compiler devs are working to fix this right now)

contract RegistryInterface {
    function initiateProvider(uint256, bytes32) public returns (bool);
    function initiateProviderCurve(bytes32, int256[], address) public returns (bool);
    function setEndpointParams(bytes32, bytes32[]) public;
    function getEndpointParams(address, bytes32) public view returns (bytes32[]);
    function getProviderPublicKey(address) public view returns (uint256);
    function getProviderTitle(address) public view returns (bytes32);
    function setProviderParameter(bytes32, bytes) public;
    function setProviderTitle(bytes32) public;
    function clearEndpoint(bytes32) public;
    function getProviderParameter(address, bytes32) public view returns (bytes);
    function getAllProviderParams(address) public view returns (bytes32[]);
    function getProviderCurveLength(address, bytes32) public view returns (uint256);
    function getProviderCurve(address, bytes32) public view returns (int[]);
    function isProviderInitiated(address) public view returns (bool);
    function getAllOracles() external view returns (address[]);
    function getProviderEndpoints(address) public view returns (bytes32[]);
    function getEndpointBroker(address, bytes32) public view returns (address);
}

// File: contracts/lib/platform/TokenDotFactory.sol

contract TokenDotFactory is Ownable {

    CurrentCostInterface currentCost;
    FactoryTokenInterface public reserveToken;
    ZapCoordinatorInterface public coord;
    TokenFactoryInterface public tokenFactory;
    BondageInterface bondage;

    mapping(bytes32 => address) public curves;

    event DotTokenCreated(address tokenAddress);

    constructor(
        address coordinator, 
        address factory,
        uint256 providerPubKey,
        bytes32 providerTitle 
    ){
        coord = ZapCoordinatorInterface(coordinator); 
        reserveToken = FactoryTokenInterface(coord.getContract("ZAP_TOKEN"));
        //always allow bondage to transfer from wallet
        reserveToken.approve(coord.getContract("BONDAGE"), ~uint256(0));
        tokenFactory = TokenFactoryInterface(factory);

        RegistryInterface registry = RegistryInterface(coord.getContract("REGISTRY")); 
        registry.initiateProvider(providerPubKey, providerTitle);
    }

    function initializeCurve(
        bytes32 specifier, 
        bytes32 symbol, 
        int256[] curve
    ) public returns(address) {
        
        require(curves[specifier] == 0, "Curve specifier already exists");
        
        RegistryInterface registry = RegistryInterface(coord.getContract("REGISTRY")); 
        require(registry.isProviderInitiated(address(this)), "Provider not intiialized");

        registry.initiateProviderCurve(specifier, curve, address(this));
        curves[specifier] = newToken(bytes32ToString(specifier), bytes32ToString(symbol));
        
        registry.setProviderParameter(specifier, toBytes(curves[specifier]));
        
        DotTokenCreated(curves[specifier]);
        return curves[specifier];
    }

    //whether this contract holds tokens or coming from msg.sender,etc
    function bond(bytes32 specifier, uint numDots) public  {

        bondage = BondageInterface(coord.getContract("BONDAGE"));
        uint256 issued = bondage.getDotsIssued(address(this), specifier);

        CurrentCostInterface cost = CurrentCostInterface(coord.getContract("CURRENT_COST"));
        uint256 numReserve = cost._costOfNDots(address(this), specifier, issued + 1, numDots - 1);

        require(
            reserveToken.transferFrom(msg.sender, address(this), numReserve),
            "insufficient accepted token numDots approved for transfer"
        );

        reserveToken.approve(address(bondage), numReserve);
        bondage.bond(address(this), specifier, numDots);
        FactoryTokenInterface(curves[specifier]).mint(msg.sender, numDots);

    }

    //whether this contract holds tokens or coming from msg.sender,etc
    function unbond(bytes32 specifier, uint numDots) public {

        bondage = BondageInterface(coord.getContract("BONDAGE"));
        uint issued = bondage.getDotsIssued(address(this), specifier);

        currentCost = CurrentCostInterface(coord.getContract("CURRENT_COST"));
        uint reserveCost = currentCost._costOfNDots(address(this), specifier, issued + 1 - numDots, numDots - 1);

        //unbond dots
        bondage.unbond(address(this), specifier, numDots);
        //burn dot backed token
        FactoryTokenInterface curveToken = FactoryTokenInterface(curves[specifier]);
        curveToken.burnFrom(msg.sender, numDots);

        require(reserveToken.transfer(msg.sender, reserveCost), "Error: Transfer failed");
    }

    function newToken(
        string name,
        string symbol
    ) 
        public
        returns (address tokenAddress) 
    {
        FactoryTokenInterface token = tokenFactory.create(name, symbol);
        tokenAddress = address(token);
        return tokenAddress;
    }

    function getTokenAddress(bytes32 specifier) public view returns(address) {
        RegistryInterface registry = RegistryInterface(coord.getContract("REGISTRY")); 
        return bytesToAddr(registry.getProviderParameter(address(this), specifier));
    }

    // https://ethereum.stackexchange.com/questions/884/how-to-convert-an-address-to-bytes-in-solidity
    function toBytes(address x) public pure returns (bytes b) {
        b = new bytes(20);
        for (uint i = 0; i < 20; i++)
            b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
    }

    //https://ethereum.stackexchange.com/questions/2519/how-to-convert-a-bytes32-to-string
    function bytes32ToString(bytes32 x) public pure returns (string) {
        bytes memory bytesString = new bytes(32);

        bytesString = abi.encodePacked(x);

        return string(bytesString);
    }

    //https://ethereum.stackexchange.com/questions/15350/how-to-convert-an-bytes-to-address-in-solidity
    function bytesToAddr (bytes b) public pure returns (address) {
        uint result = 0;
        for (uint i = b.length-1; i+1 > 0; i--) {
            uint c = uint(b[i]);
            uint to_inc = c * ( 16 ** ((b.length - i-1) * 2));
            result += to_inc;
        }
        return address(result);
    }


}