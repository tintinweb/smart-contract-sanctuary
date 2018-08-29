pragma solidity 0.4.24;
// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="bdd9dccbd8fddcd6d2d0dfdc93ded2d0">[email&#160;protected]</a>
// released under Apache 2.0 licence
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract APIRegistry is Ownable {

    struct APIForSale {
        uint pricePerCall;
        bytes32 sellerUsername;
        bytes32 apiName;
        address sellerAddress;
        string hostname;
        string docsUrl;
    }

    mapping(string => uint) internal apiIds;
    mapping(uint => APIForSale) public apis;

    uint public numApis;
    uint public version;

    // ------------------------------------------------------------------------
    // Constructor, establishes ownership because contract is owned
    // ------------------------------------------------------------------------
    constructor() public {
        numApis = 0;
        version = 1;
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens (just in case)
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }

    // ------------------------------------------------------------------------
    // Lets a user list an API to sell
    // ------------------------------------------------------------------------
    function listApi(uint pricePerCall, bytes32 sellerUsername, bytes32 apiName, string hostname, string docsUrl) public {
        // make sure input params are valid
        require(pricePerCall != 0 && sellerUsername != "" && apiName != "" && bytes(hostname).length != 0);
        
        // make sure the name isn&#39;t already taken
        require(apiIds[hostname] == 0);

        numApis += 1;
        apiIds[hostname] = numApis;

        APIForSale storage api = apis[numApis];

        api.pricePerCall = pricePerCall;
        api.sellerUsername = sellerUsername;
        api.apiName = apiName;
        api.sellerAddress = msg.sender;
        api.hostname = hostname;
        api.docsUrl = docsUrl;
    }

    // ------------------------------------------------------------------------
    // Get the ID number of an API given it&#39;s hostname
    // ------------------------------------------------------------------------
    function getApiId(string hostname) public view returns (uint) {
        return apiIds[hostname];
    }

    // ------------------------------------------------------------------------
    // Get info stored for the API but without the dynamic members, because solidity can&#39;t return dynamics to other smart contracts yet
    // ------------------------------------------------------------------------
    function getApiByIdWithoutDynamics(
        uint apiId
    ) 
        public
        view 
        returns (
            uint pricePerCall, 
            bytes32 sellerUsername,
            bytes32 apiName, 
            address sellerAddress
        ) 
    {
        APIForSale storage api = apis[apiId];

        pricePerCall = api.pricePerCall;
        sellerUsername = api.sellerUsername;
        apiName = api.apiName;
        sellerAddress = api.sellerAddress;
    }

    // ------------------------------------------------------------------------
    // Get info stored for an API by id
    // ------------------------------------------------------------------------
    function getApiById(
        uint apiId
    ) 
        public 
        view 
        returns (
            uint pricePerCall, 
            bytes32 sellerUsername, 
            bytes32 apiName, 
            address sellerAddress, 
            string hostname, 
            string docsUrl
        ) 
    {
        APIForSale storage api = apis[apiId];

        pricePerCall = api.pricePerCall;
        sellerUsername = api.sellerUsername;
        apiName = api.apiName;
        sellerAddress = api.sellerAddress;
        hostname = api.hostname;
        docsUrl = api.docsUrl;
    }

    // ------------------------------------------------------------------------
    // Get info stored for an API by hostname
    // ------------------------------------------------------------------------
    function getApiByName(
        string _hostname
    ) 
        public 
        view 
        returns (
            uint pricePerCall, 
            bytes32 sellerUsername, 
            bytes32 apiName, 
            address sellerAddress, 
            string hostname, 
            string docsUrl
        ) 
    {
        uint apiId = apiIds[_hostname];
        if (apiId == 0) {
            return;
        }
        APIForSale storage api = apis[apiId];

        pricePerCall = api.pricePerCall;
        sellerUsername = api.sellerUsername;
        apiName = api.apiName;
        sellerAddress = api.sellerAddress;
        hostname = api.hostname;
        docsUrl = api.docsUrl;
    }

    // ------------------------------------------------------------------------
    // Edit an API listing
    // ------------------------------------------------------------------------
    function editApi(uint apiId, uint pricePerCall, address sellerAddress, string docsUrl) public {
        require(apiId != 0 && pricePerCall != 0 && sellerAddress != address(0));

        APIForSale storage api = apis[apiId];

        // prevent editing an empty api (effectively listing an api)
        require(
            api.pricePerCall != 0 && api.sellerUsername != "" && api.apiName != "" &&  bytes(api.hostname).length != 0 && api.sellerAddress != address(0)
        );

        // require that sender is the original api lister, or the contract owner
        // the contract owner clause lets us recover a api listing if a dev loses access to their privkey
        require(msg.sender == api.sellerAddress || msg.sender == owner);

        api.pricePerCall = pricePerCall;
        api.sellerAddress = sellerAddress;
        api.docsUrl = docsUrl;
    }
}