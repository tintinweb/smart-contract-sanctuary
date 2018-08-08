pragma solidity ^0.4.15;


/* taking ideas from FirstBlood token */
contract RpSafeMath {
    function safeAdd(uint256 x, uint256 y) internal pure returns(uint256) {
      uint256 z = x + y;
      require((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal pure returns(uint256) {
      require(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) internal pure returns(uint256) {
      uint256 z = x * y;
      require((x == 0)||(z/x == y));
      return z;
    }

    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a < b) { 
          return a;
        } else { 
          return b; 
        }
    }
    
    function max(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a > b) { 
          return a;
        } else { 
          return b; 
        }
    }
}

contract Token {
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success);
    function balanceOf(address _owner) public view returns (uint256 balance);
}

contract BytesUtils {
    function readBytes32(bytes data, uint256 index) internal pure returns (bytes32 o) {
        require(data.length / 32 > index);
        assembly {
            o := mload(add(data, add(32, mul(32, index))))
        }
    }
}

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    /**
        @dev Transfers the ownership of the contract.

        @param _to Address of the new owner
    */
    function transferTo(address _to) public onlyOwner returns (bool) {
        require(_to != address(0));
        owner = _to;
        return true;
    }
}

interface ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable returns(bool);
    function approve(address _approved, uint256 _tokenId) external payable returns(bool);
    function getApproved(uint256 _tokenId) external view returns (address);
}

contract ErcBundle is ERC721, BytesUtils, Ownable, RpSafeMath {
    mapping (uint256 => address) bundleToOwner;
    mapping (uint256 => address) bundleToApproved;
    mapping (address => uint256) addresToBalance;

    Bundle[] private bundles;
    struct Bundle {
        mapping (address => uint) erc20ToBalance; // a mapping for ERC20 balances
        Token[] erc20Addrs; // an array of ERC20 address
        mapping (address => uint[]) erc721ToNfts; // a mapping for ERC721 non fungible tokens
        ERC721[] erc721Addrs; // an array of ERC721 address
    }

    // create bundle
    /**
    @notice Create a empty Bundle in bundles array
    */
    function createBundle() public returns(bool) {
        bundleToOwner[bundles.length] = msg.sender;
        addresToBalance[msg.sender]++;
        bundles.push(Bundle(new Token[](0), new ERC721[](0)));// push two empty array
        return true;
    }
    /**
    @notice Add an ERC20 in a exist element of bundles array and add balance

    @dev if the ERC20 its not inside of erc20Addrs array, add it
          Transfer amount to the contract, and add balance to bundle

    @param _bundleId index of bundles array
    @param _erc20 address of ERC20 contract
    */
    function addERC20ToBundle(uint _bundleId, Token _erc20, uint _amount) public returns(bool) {
        require(bundleToOwner[_bundleId] == msg.sender, "sender its not the owner");

        require(_erc20.transferFrom(msg.sender, address(this), _amount), "the transfer its no approved");

        Bundle storage bundle = bundles[_bundleId];
        if(bundle.erc20ToBalance[_erc20] == 0){
            bundle.erc20Addrs.push(_erc20);
            bundle.erc20ToBalance[_erc20] = _amount;
        } else {
            bundle.erc20ToBalance[_erc20] = safeAdd(bundle.erc20ToBalance[_erc20], _amount);
        }
        return true;
    }
    /**
    @notice Add an ERC721 in a exist element of bundles array and add non fungible tokens

    @dev if the ERC721 its not inside of erc721Addrs array, add it
          Transfer all non fungible tokens to the contract, and all non fungible tokens to bundle

    @param _bundleId index of bundles array
    @param _erc721 address of ERC721 contract
    */
    function addERC721ToBundle(uint _bundleId, ERC721 _erc721, uint[] _nfts) public returns(bool) {
        require(bundleToOwner[_bundleId] == msg.sender, "sender its not the owner");
        require(_nfts.length > 0, "need at last one nft");

        Bundle storage bundle = bundles[_bundleId];
        uint[] storage nfts = bundle.erc721ToNfts[_erc721];

        if(nfts.length == 0)
            bundle.erc721Addrs.push(_erc721);
        for(uint i; i < _nfts.length; i++){
            require(_erc721.transferFrom(msg.sender, address(this), _nfts[i]), "the transfer its no approved");
            nfts.push(_nfts[i]);
        }
        return true;
    }

    // Withdraw functions
    /**
    @notice Add an ERC20 in a exist element of bundles array and add non fungible tokens

    @dev if the ERC20 its not inside of erc20Addrs array, add it
          Transfer all non fungible tokens to the contract, and all non fungible tokens to bundle

    @param _bundleId index of bundles array
    @param _erc20Id index of ERC20 contract
    @param _to destination address of ERC20 amount
    */
    function withdrawERC20(uint256 _bundleId, uint _erc20Id, address _to, uint _amount) public returns(bool){
        require(bundleToOwner[_bundleId] == msg.sender, "sender its not the owner");
        Bundle storage bundle = bundles[_bundleId];
        Token erc20 = bundle.erc20Addrs[_erc20Id];
        require(bundle.erc20ToBalance[erc20] >= _amount, "low balance");

        bundle.erc20ToBalance[erc20] = safeSubtract(bundle.erc20ToBalance[erc20], _amount);
        require(erc20.transfer(_to, _amount), "fail token transfer");

        if(bundle.erc20ToBalance[erc20] == 0) {
            if(bundle.erc20Addrs.length > 1)
                bundle.erc20Addrs[_erc20Id] = bundle.erc20Addrs[bundle.erc20Addrs.length - 1];
            bundle.erc20Addrs.length -= 1;
        }

        return true;
    }
    /**
    @notice Add an ERC721 in a exist element of bundles array and add non fungible tokens

    @dev if the ERC721 its not inside of erc721Addrs array, add it
          Transfer all non fungible tokens to the contract, and all non fungible tokens to bundle

    @param _bundleId index of bundles array
    @param _erc721Id index of ERC721 contract
    @param _to destination address of non fungible token
    @param _nftId index of non fungible token in non fungible token array
    */
    function withdrawERC721(uint256 _bundleId, uint _erc721Id, address _to, uint _nftId) public returns(bool){
        require(bundleToOwner[_bundleId] == msg.sender, "sender its not the owner");
        Bundle storage bundle = bundles[_bundleId];
        ERC721 erc721 = bundle.erc721Addrs[_erc721Id];
        uint nft = bundle.erc721ToNfts[erc721][_nftId];

        if(bundle.erc721ToNfts[erc721].length > 1)
            bundle.erc721ToNfts[erc721][_nftId] = bundle.erc721ToNfts[erc721][bundle.erc721ToNfts[erc721].length - 1];
        bundle.erc721ToNfts[erc721].length -= 1;

        require(erc721.transferFrom(address(this), _to, nft), "fail nft transfer");

        if(bundle.erc721ToNfts[erc721].length == 0) {
            if(bundle.erc721Addrs.length > 1)
                bundle.erc721Addrs[_erc721Id] = bundle.erc721Addrs[bundle.erc721Addrs.length - 1];
            bundle.erc721Addrs.length -= 1;
        }

        return true;
    }

    // ERC721 standard functions
    function getApproved(uint256 _bundleId) external view returns (address) { return bundleToApproved[_bundleId]; }

    function ownerOf(uint256 _bundleId) external view returns (address) { return bundleToOwner[_bundleId]; }

    function balanceOf(address _owner) external view returns (uint256) { return addresToBalance[_owner]; }

    function approve(address _approved, uint256 _bundleId) external payable returns(bool) {
        require(msg.sender == bundleToOwner[_bundleId], "sender its not the owner");
        require(msg.sender != _approved, "sender and approved should not be equal");

        bundleToApproved[_bundleId] = _approved;

        emit Approval(msg.sender, _approved, _bundleId);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _bundleId) external payable returns(bool) {
        address owner = bundleToOwner[_bundleId];
        require(owner != 0x0, "the bundle dont exist");
        require(owner == msg.sender || bundleToApproved[_bundleId] == msg.sender, "sender its not the owner or not approved");
        require(owner != _to, "the owner and `_to` should not be equal");
        require(owner == _from, "the owner and `_from` should be equal");
        require(_to != address(0), "`_to` is the zero address");

        addresToBalance[_from]--;
        addresToBalance[_to]++;

        bundleToOwner[_bundleId] = _to;

        emit Transfer(msg.sender, _to, _bundleId);

        return true;
    }

    // Getters
    /**
    @notice Get the ERC20 address index

    @param _bundleId index of bundles array
    @param _erc20 address of ERC20 contract

    @return the index of ERC20 address in erc20Addrs array
    */
    function getERC20Id(uint _bundleId, address _erc20) public view returns(uint erc20Id) {
        Token[] storage erc20s = bundles[_bundleId].erc20Addrs;

        for(uint i; i < erc20s.length; i++)
            if(erc20s[i] == _erc20)
                return i;
        revert("ERC20 dont found");
    }
    /**
    @notice Get all address of ERC20 contracts with his balances

    @param _bundleId index of bundles array

    @return a tuple, with two arrays, one of ERC20 address and other of balances
    */
    function getAllERC20(uint _bundleId) public view returns(address[] memory addrs, uint[] memory balances){
        Token[] storage erc20s = bundles[_bundleId].erc20Addrs;

        uint length = erc20s.length;
        addrs = new address[](length);
        balances = new uint[](length);

        for(uint i; i < length; i++){
            addrs[i] = erc20s[i];
            balances[i] = bundles[_bundleId].erc20ToBalance[erc20s[i]];
        }
    }
    /**
    @notice Get the ERC721 address index

    @param _bundleId index of bundles array
    @param _erc721 address of ERC721 contract

    @return the index of ERC721 address in erc721Addrs array
    */
    function getERC721Id(uint _bundleId, address _erc721) public view returns(uint erc721Id) {
        ERC721[] storage erc721s = bundles[_bundleId].erc721Addrs;

        for(uint i; i < erc721s.length; i++)
            if(erc721s[i] == _erc721)
                return i;
        revert("ERC721 not found");
    }
    /**
    @notice Get the non fungible token index

    @param _bundleId index of bundles array
    @param _erc721 address of ERC721 contract
    @param _nft id of non fungible token

    @return a non fungible token index of bundle nfts array
    */
    function getNftId(uint _bundleId, address _erc721, uint _nft) public view returns(uint nftId) {
        uint[] storage nfts = bundles[_bundleId].erc721ToNfts[_erc721];

        for(uint i; i < nfts.length; i++)
            if(nfts[i] == _nft)
                return i;
        revert("nft not found");
    }
    /**
    @notice Get all address of ERC721 contracts

    @param _bundleId index of bundles array

    @return an array of ERC721 address
    */
    function getERC721Addrs(uint _bundleId) public view returns(ERC721[] addrs){
        return bundles[_bundleId].erc721Addrs;
    }
    /**
    @notice Get all the non fungible token of an ERC721 inside a bundle

    @param _bundleId index of bundles array
    @param _addr adress of ERC721

    @return an array of non fungible token
    */
    function getERC721Nfts(uint _bundleId, address _addr) public view returns(uint[] nfts){
        return bundles[_bundleId].erc721ToNfts[_addr];
    }
    /**
        @notice Returns all the bundleId that a owner possess
        @dev This method MUST NEVER be called by smart contract code;
            it walks the entire bundle array, and will probably create a transaction bigger than the gas limit.

        @param _owner The owner address

        @return bundleIds List of all the bundle indexes of the _owner
    */
    function bundleOfOwner(address _owner) external view returns(uint256[]) {
        uint256 bundleCount = this.balanceOf(_owner);

        if (bundleCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory bundleIds = new uint256[](bundleCount);
            uint256 totalBundles = bundles.length;

            uint256 j;
            for (uint256 i; i < totalBundles; i++){
                if(bundleToOwner[i] == _owner) {
                    bundleIds[j] = i;
                    j++;
                }
                if(j >= bundleCount) return bundleIds;
            }
        }
    }
}