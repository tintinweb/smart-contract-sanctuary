/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

pragma solidity ^0.5.0;

library Address {

    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solium-disable-next-line security/no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

}


/// @dev Note: the ERC-165 identifier for this interface is 0xf23a6e61.
interface IERC1155TokenReceiver {
    /// @notice Handle the receipt of an ERC1155 type
    /// @dev The smart contract calls this function on the recipient
    ///  after a `safeTransfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _id The identifier of the item being transferred
    /// @param _value The amount of the item being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    ///  unless throwing
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);
}

interface IERC1155 {
    event Approval(address indexed _owner, address indexed _spender, uint256 indexed _id, uint256 _oldValue, uint256 _value);
    event Transfer(address _spender, address indexed _from, address indexed _to, uint256 indexed _id, uint256 _value);

    function transferFrom(address _from, address _to, uint256 _id, uint256 _value) external;
    //function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function approve(address _spender, uint256 _id, uint256 _currentValue, uint256 _value) external;
    function balanceOf(uint256 _id) external view returns (uint256);
    function allowance(uint256 _id, address _owner, address _spender) external view returns (uint256);
}

interface IERC1155Extended {
    function transfer(address _to, uint256 _id, uint256 _value) external;
   // function safeTransfer(address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
}


interface IERC1155Operators {
    event OperatorApproval(address indexed _owner, address indexed _operator, uint256 indexed _id, bool _approved);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function setApproval(address _operator, uint256[] calldata _ids, bool _approved) external;
    function isApproved(address _owner, address _operator, uint256 _id)  external view returns (bool);
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}

interface IERC1155Views {
    function totalSupply(uint256 _id) external view returns (uint256);
    function name(uint256 _id) external view returns (string memory);
    function symbol(uint256 _id) external view returns (string memory);
    function decimals(uint256 _id) external view returns (uint8);
    function uri(uint256 _id) external view returns (string memory);
}


interface IERC1155NonFungible {
    // Optional Functions for Non-Fungible Items
    function ownerOf(uint256 _id) external view returns (address);
    function nonFungibleByIndex(uint256 _id, uint128 _index) external view returns (uint256);
    function nonFungibleOfOwnerByIndex(uint256 _id, address _owner, uint128 _index) external view returns (uint256);
    function isNonFungible(uint256 _id) external view returns (bool);
}




library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


contract ERC1155 is IERC1155, IERC1155Extended {
    using SafeMath for uint256;
    using Address for address;

    // Variables
    struct Items {
        string name;
        uint256 totalSupply;
        mapping (address => uint256) balances;
    }
    
    mapping (uint256 => string) public symbols;
    mapping (uint256 => mapping(address => mapping(address => uint256))) public allowances;
    mapping (uint256 => Items) public items;
    mapping (uint256 => string) public metadataURIs;

    mapping (uint256 => address) public owners;

  //  bytes4 constant private ERC1155_RECEIVED = 0xf23a6e61;

/////////////////////////////////////////// IERC1155 //////////////////////////////////////////////

    // Events
    event Approval(address indexed _owner, address indexed _spender, uint256 indexed _id, uint256 _oldValue, uint256 _value);
    event Transfer(address _spender, address indexed _from, address indexed _to, uint256 indexed _id, uint256 _value);

    function transferFrom(address _from, address _to, uint256 _id, uint256 _value) external {
        if(_from != msg.sender) {
            //require(allowances[_id][_from][msg.sender] >= _value);
            allowances[_id][_from][msg.sender] = allowances[_id][_from][msg.sender].sub(_value);
        }

        items[_id].balances[_from] = items[_id].balances[_from].sub(_value);
        items[_id].balances[_to] = _value.add(items[_id].balances[_to]);
        owners[_id]=_to; 
        emit Transfer(msg.sender, _from, _to, _id, _value);
    }

   
    function approve(address _spender, uint256 _id, uint256 _currentValue, uint256 _value) external {
        // if the allowance isn't 0, it can only be updated to 0 to prevent an allowance change immediately after withdrawal
        require(_value == 0 || allowances[_id][msg.sender][_spender] == _currentValue);
        allowances[_id][msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _id, _currentValue, _value);
    }

    function balanceOf(uint256 _id) external view returns (uint256) {
        return items[_id].balances[msg.sender];
    }

    function allowance(uint256 _id, address _owner, address _spender) external view returns (uint256) {
        return allowances[_id][_owner][_spender];
    }


/////////////////////////////////////// IERC1155Extended //////////////////////////////////////////

    function transfer(address _to, uint256 _id, uint256 _value) external {
        // Not needed. SafeMath will do the same check on .sub(_value)
        //require(_value <= items[_id].balances[msg.sender]);
        items[_id].balances[msg.sender] = items[_id].balances[msg.sender].sub(_value);
        items[_id].balances[_to] = _value.add(items[_id].balances[_to]);
        owners[_id]=_to;
        emit Transfer(msg.sender, msg.sender, _to, _id, _value);
    }

  

//////////////////////////////// IERC1155BatchTransferExtended ////////////////////////////////////

    // Optional meta data view Functions
    // consider multi-lingual support for name?
    function name(uint256 _id) external view returns (string memory) {
        return items[_id].name;
    }

    function symbol(uint256 _id) external view returns (string memory) {
        return symbols[_id];
    }

    

    function totalSupply(uint256 _id) external view returns (uint256) {
        return items[_id].totalSupply;
    }

    function uri(uint256 _id) external view returns (string memory) {
        return metadataURIs[_id];
    }

    function token(uint256 _id) external view returns (string memory, string memory, uint256, string memory) {
        return (items[_id].name, symbols[_id], items[_id].totalSupply, metadataURIs[_id]);
    }
  


}

contract Polly is ERC1155 {
    mapping (uint256 => address) public minters;
    address administrator=0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    
    uint public assetCount = 0;

    modifier minterOnly(uint256 _id) {
        require(minters[_id] == msg.sender);
        _;
    }

    function mint(string calldata _name, uint256 _totalSupply, string calldata _uri, string calldata _symbol)  
    external returns(uint256 _id)  {
        //TODO add require to avoid duplicate items
        assetCount ++;
        _id = assetCount;
    
        if(msg.sender != administrator){
            revert("Only administrator can mint the NFT");
        }
    
        uint flag = 0;
        for (uint256 i = 0; i <= assetCount ; ++i) {
             if(keccak256(abi.encodePacked(symbols[i] )) == keccak256(abi.encodePacked(_symbol))){
                flag=1;
             }
       }
        
       if (flag==1){
         revert("Property already exist");
       } 
       if (keccak256(abi.encodePacked(items[_id].name)) != keccak256(abi.encodePacked(""))){
         revert("Property already exist");
       }
        
        
        minters[_id] = msg.sender; 

        items[_id].name = _name;
        items[_id].totalSupply = _totalSupply;
        metadataURIs[_id] = _uri;
        symbols[_id] = _symbol;
        
        owners[_id]=msg.sender; 
        
        
        // Grant the items to the minter
        items[_id].balances[msg.sender] = _totalSupply;
        return _id;
    }

    function setURI(uint256 _id, string calldata _uri) external minterOnly(_id) {
        metadataURIs[_id] = _uri;
    }

    function returnAssetCount () external view returns(uint) {
        return assetCount;
    }
    function returnTotalProperties(address _walletAddress) external view returns(uint) {
        uint total=0;
         for (uint256 i = 0; i <= assetCount ; ++i) {
             if(owners[i] == _walletAddress){
                 total = total + 1;
             }
        }
        return total;
    }
    function returnMyTotalNFT(address _walletAddress) external view returns(uint) {
        uint total=0;
         for (uint256 i = 0; i <= assetCount ; ++i) {
             if(owners[i] == _walletAddress){
                 total = total + items[i].totalSupply;
             }
        }
        return total;
    }
    function returnMyProperties(address _walletAddress) external view returns(string memory) {
        string memory ids;
        uint flag=0;
        for (uint256 i = 0; i <= assetCount ; ++i) {
             if(owners[i] == _walletAddress){
                 if(flag==0){
                     flag=1; 
                    ids=string(abi.encodePacked(ids,uint2str(i)));       
                 }
                 else{
                     ids=string(abi.encodePacked(ids,",",uint2str(i)));
                 }
             }
        }
        
        return ids; 
    }
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
    return string(bstr);
    }
}