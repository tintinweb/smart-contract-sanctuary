pragma solidity ^0.4.20;

/** 
 * Created by RigCraft Team
 * If you have any questions please visit the official discord channel
 * https://discord.gg/zJCf7Fh
 * or read The FAQ at 
 * https://rigcraft.io/#faq
 **/

contract ERC721Basic {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId) public view returns (address _operator);
  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data ) public;
}

contract ERC721Receiver {

  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

  function onERC721Received(address _from,uint256 _tokenId,bytes _data) public returns(bytes4);
}

contract ERC721Metadata {
   
    function tokenURI(uint256 _tokenId) external view returns (string);
}

contract Administration
{
    address owner;
    bool active = true;
    bool open = true;
    
    function Administration() public
    {
        owner = msg.sender;
    }
    
    modifier onlyOwner() 
    {
        require(owner == msg.sender);
        _;
    }
    
    modifier isActive()
    {
        require(active == true);
        _;
    }
    
    modifier isOpen()
    {
        require(open == true);
        _;
    }
    
    function setActive(bool _active) external onlyOwner
    {
        active = _active;
    }
    
    function setOpen(bool _open) external onlyOwner
    {
        open = _open;
    }
}

// core
contract RigCraftPresalePackageToken is ERC721Basic, Administration, ERC721Metadata {
    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;
    
    struct PresalePackage
    {
        uint8 packageId;
        uint16 serialNumber;
    }
    
    PresalePackage[] packages;
    
    // Mapping from token ID to owner
    mapping (uint256 => address) internal tokenOwner;
    mapping (uint256 => address) internal tokenApprovals;
    mapping (address => uint256) internal ownedTokensCount;
    mapping (address => mapping (address => bool)) internal operatorApprovals;
    
    RigCraftPresalePackageManager private presaleHandler;
    string URIBase;
    
    string public constant name = "RigCraftPresalePackage";
    string public constant symbol = "RCPT";
    
    function SetPresaleHandler(address addr) external onlyOwner
    {
        presaleHandler = RigCraftPresalePackageManager(addr);
    }
    
    function setURIBase(string _base) external onlyOwner
    {
        URIBase = _base;
    }
    
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }

    modifier canTransfer(uint256 _tokenId) {
        require(isApprovedOrOwner(msg.sender, _tokenId));
        _;
    }
    
    /**
    * PUBLIC INTERFACE
    **/
    function balanceOf(address _owner) public view isOpen returns (uint256) {
        require(_owner != address(0));
        return ownedTokensCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view isOpen returns (address) {
        address owner = tokenOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }

    function exists(uint256 _tokenId) public view isOpen returns (bool) {
        address owner = tokenOwner[_tokenId];
        return owner != address(0);
    }
    
    function totalSupply() public view returns (uint256) {
        return packages.length;
    }

    function approve(address _to, uint256 _tokenId) public
    isOpen
    isActive
    {
        address owner = ownerOf(_tokenId);
        require(_to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));
        
        if (getApproved(_tokenId) != address(0) || _to != address(0)) {
            tokenApprovals[_tokenId] = _to;
            emit Approval(owner, _to, _tokenId);
        }
    }
    
    function getApproved(uint256 _tokenId) public view isOpen returns (address) {
        return tokenApprovals[_tokenId];
    }
    
    function setApprovalForAll(address _to, bool _approved) public
    isActive
    isOpen
    {
        require(_to != msg.sender);
        operatorApprovals[msg.sender][_to] = _approved;
        emit ApprovalForAll(msg.sender, _to, _approved);
    }

    function isApprovedForAll( address _owner, address _operator) public view
    isOpen
    returns (bool)
    {
        return operatorApprovals[_owner][_operator];
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public
    canTransfer(_tokenId)
    isActive
    isOpen
    {
        require(_from != address(0));
        require(_to != address(0));
        
        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);
        
        emit Transfer(_from, _to, _tokenId);
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public
    canTransfer(_tokenId)
    isActive
    isOpen
    {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data)
    public
    canTransfer(_tokenId)
    isActive
    isOpen
    {
        transferFrom(_from, _to, _tokenId);
        require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
    }

    /**
    * INTERNALS
    **/
    function isApprovedOrOwner(address _spender,uint256 _tokenId) internal view
    returns (bool)
    {
        address owner = ownerOf(_tokenId);
        return (_spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender));
    }
    
    function clearApproval(address _owner, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _owner);
        if (tokenApprovals[_tokenId] != address(0)) {
            tokenApprovals[_tokenId] = address(0);
            emit Approval(_owner, address(0), _tokenId);
        }
    }

    function addTokenTo(address _to, uint256 _tokenId) internal 
    {
        require(tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        ownedTokensCount[_to] += 1;
    }

    function removeTokenFrom(address _from, uint256 _tokenId) internal 
    {
        require(ownerOf(_tokenId) == _from);
        require(ownedTokensCount[_from] > 0);
        ownedTokensCount[_from] -= 1;
        tokenOwner[_tokenId] = address(0);
    }

    function checkAndCallSafeTransfer(address _from, address _to, uint256 _tokenId, bytes _data)
    internal
    returns (bool)
    {
        uint256 codeSize;
        assembly { codeSize := extcodesize(_to) }
        if (codeSize == 0) {
            return true;
        }
        bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
        return (retval == ERC721_RECEIVED);
    }
    
    function tokenURI(uint256 _tokenId) external view returns (string)
    {
        string memory tokenNumber = uint2str(_tokenId);
        
        uint pos = bytes(URIBase).length;
        bytes memory retVal  = new bytes(bytes(tokenNumber).length + bytes(URIBase).length);
        uint i = 0;
        
        for(i = 0; i < bytes(URIBase).length; ++i)
        {
            retVal[i] = bytes(URIBase)[i];
        }
        for(i = 0; i < bytes(tokenNumber).length; ++i)
        {
            retVal[pos + i] = bytes(tokenNumber)[i];
        }
        
        return string(retVal);
    }
    
    function uint2str(uint256 i) internal pure returns (string)
    {
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0){
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }
    
    // Get all token IDs of address
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) 
    {
        uint256 tokenCount = balanceOf(_owner);
        
        if (tokenCount == 0) 
        {
            // Return an empty array
            return new uint256[](0);
        } else 
        {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 resultIndex = 0;
            
            // We count on the fact that all cats have IDs starting at 1 and increasing
            // sequentially up to the totalCat count.
            uint256 tokenId;
            
            for (tokenId = 0; tokenId < packages.length; tokenId++) 
            {
                if (tokenOwner[tokenId] == _owner) 
                {
                    result[resultIndex] = tokenId;
                    resultIndex++;
                }
            }
        
            return result;
        }
    }
    
    /**
    * EXTERNALS
    **/
    function GetTokenData(uint256 _tokenId) external view returns(uint8 presalePackadeId, uint16 serialNO) 
    {
        require(_tokenId < packages.length);
        
        presalePackadeId = packages[_tokenId].packageId;
        serialNO = packages[_tokenId].serialNumber;
    }
    
    function CreateToken(address _owner, uint8 _packageId, uint16 _serial) external
    isActive
    isOpen
    {
        require(msg.sender == address(presaleHandler));
        uint256 tokenId = packages.length;
        packages.length += 1;
        
        packages[tokenId].packageId = _packageId;
        packages[tokenId].serialNumber = _serial;
        
        addTokenTo(_owner, tokenId);
    }
}

// presale
contract RigCraftPresalePackageManager
{
    address owner;
    
    bool public isActive;
    
    uint16[]    public presalePackSold;
    uint16[]    public presalePackLimit;
    uint256[]   public presalePackagePrice;
    
    mapping(address=>uint256) addressRefferedCount;
    mapping(address=>uint256) addressRefferredSpending;
    address[] referralAddressIndex;
    
    uint256 public totalFundsSoFar;
    
    RigCraftPresalePackageToken private presaleTokenContract;
    
    function RigCraftPresalePackageManager() public
    {
        owner = msg.sender;
        isActive = false;
        presaleTokenContract = RigCraftPresalePackageToken(address(0));
        
        presalePackSold.length     = 5;
        presalePackLimit.length    = 5;
        presalePackagePrice.length = 5;
       
        // starter pack 
        presalePackLimit[0]    = 65000;
        presalePackagePrice[0] = 0.1 ether;
        
        // snow white
        presalePackLimit[1]    = 50;
        presalePackagePrice[1] = 0.33 ether;
        
        // 6x66 black
        presalePackLimit[2]    = 66;
        presalePackagePrice[2] = 0.66 ether;
        
        // blue legandary
        presalePackLimit[3]    = 50;
        presalePackagePrice[3] = 0.99 ether;
        
        // lifetime share
        presalePackLimit[4]    = 100;
        presalePackagePrice[4] = 1 ether;
    }
    
    function SetActive(bool _active) external
    {
        require(msg.sender == owner);
        isActive = _active;
    } 
    
    function SetPresaleHandler(address addr) external
    {
        require(msg.sender == owner);
        presaleTokenContract = RigCraftPresalePackageToken(addr);
    }
    
    function AddNewPresalePackage(uint16 limit, uint256 price) external 
    {
        require(msg.sender == owner);
        require(limit > 0);
        require(isActive);
        
        presalePackLimit.length += 1;
        presalePackLimit[presalePackLimit.length-1] = limit;
        
        presalePackagePrice.length += 1;
        presalePackagePrice[presalePackagePrice.length-1] = price;
        
        presalePackSold.length += 1;
    }
    
    // ETH handler
    function BuyPresalePackage(uint8 packageId, address referral) external payable
    {
        require(isActive);
        require(packageId < presalePackLimit.length);
        require(msg.sender != referral);
        require(presalePackLimit[packageId] > presalePackSold[packageId]);

        require(presaleTokenContract != RigCraftPresalePackageToken(address(0)));

        // check money
        require(msg.value >= presalePackagePrice[packageId]);
        
        presalePackSold[packageId]++;
        
        totalFundsSoFar += msg.value;
        
        presaleTokenContract.CreateToken(msg.sender, packageId, presalePackSold[packageId]);
        
        if(referral != address(0))
        {
            if(addressRefferedCount[referral] == 0)
            {
                referralAddressIndex.length += 1;
                referralAddressIndex[referralAddressIndex.length-1] = referral;
            }
            addressRefferedCount[referral] += 1;
            addressRefferredSpending[referral] += msg.value;
        }
    }

    // referral system 
    function GetAllReferralAddresses() external view returns (address[] referred)
    {
        referred = referralAddressIndex;
    }
    
    function GetReferredCount() external view returns (uint256)
    {
        return referralAddressIndex.length;
    }
    
    function GetReferredAt(uint256 idx) external view returns (address)
    {
        require(idx < referralAddressIndex.length);
        return referralAddressIndex[idx];
    }
    
    function GetReferralDataOfAddress(address addr) external view returns (uint256 count, uint256 spending)
    {
        count = addressRefferedCount[addr];
        spending = addressRefferredSpending[addr];
    }

    // withdraw 
    function withdraw() external
    {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    }
}