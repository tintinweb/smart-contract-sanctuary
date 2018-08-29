pragma solidity ^0.4.24;


//import "./SafeMath.sol";


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
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes _data) external returns(bytes4);
}

interface IERC1155 {
    event Approval(address indexed _owner, address indexed _spender, uint256 indexed _id, uint256 _oldValue, uint256 _value);
    event Transfer(address _spender, address indexed _from, address indexed _to, uint256 indexed _id, uint256 _value);

    function transferFrom(address _from, address _to, uint256 _id, uint256 _value) external;
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes _data) external;
    function approve(address _spender, uint256 _id, uint256 _currentValue, uint256 _value) external;
    function balanceOf(uint256 _id, address _owner) external view returns (uint256);
    function allowance(uint256 _id, address _owner, address _spender) external view returns (uint256);
}

interface IERC1155Extended {
    function transfer(address _to, uint256 _id, uint256 _value) external;
    function safeTransfer(address _to, uint256 _id, uint256 _value, bytes _data) external;
}

interface IERC1155BatchTransfer {
    function batchTransferFrom(address _from, address _to, uint256[] _ids, uint256[] _values) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] _ids, uint256[] _values, bytes _data) external;
    function batchApprove(address _spender, uint256[] _ids,  uint256[] _currentValues, uint256[] _values) external;
}

interface IERC1155BatchTransferExtended {
    function batchTransfer(address _to, uint256[] _ids, uint256[] _values) external;
    function safeBatchTransfer(address _to, uint256[] _ids, uint256[] _values, bytes _data) external;
}

interface IERC1155Operators {
    event OperatorApproval(address indexed _owner, address indexed _operator, uint256 indexed _id, bool _approved);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function setApproval(address _operator, uint256[] _ids, bool _approved) external;
    function isApproved(address _owner, address _operator, uint256 _id)  external view returns (bool);
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}

interface IERC1155Views {
    function totalSupply(uint256 _id) external view returns (uint256);
    function name(uint256 _id) external view returns (string);
    function symbol(uint256 _id) external view returns (string);
    function decimals(uint256 _id) external view returns (uint8);
    function uri(uint256 _id) external view returns (string);
}



/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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


contract ERC1155 is IERC1155, IERC1155Extended, IERC1155BatchTransfer, IERC1155BatchTransferExtended {
    using SafeMath for uint256;

    // Variables
    struct Item {
        string name;
        uint256 totalSupply;
        mapping (address => uint256) balances;
    }
    mapping (uint256 => uint8) public decimals;
    mapping (uint256 => string) public symbols;
    mapping (uint256 => mapping(address => mapping(address => uint256))) allowances;
    mapping (uint256 => Item) public items;
    mapping (uint256 => string) metadataURIs;


    mapping (uint256 => uint256) public types; // for test
    function getType(uint256 _id) external view returns (uint256) {
        return types[_id];
    }

    /////////////////////////////////////////// IERC1155 //////////////////////////////////////////////

    // Events
    event Approval(address indexed _owner, address indexed _spender, uint256 indexed _id, uint256 _oldValue, uint256 _value);
    event Transfer(address _spender, address indexed _from, address indexed _to, uint256 indexed _id, uint256 _value);

    function transferFrom(address _from, address _to, uint256 _id, uint256 _value) external {
        if(_from != msg.sender) {
            require(allowances[_id][_from][msg.sender] >= _value);
            allowances[_id][_from][msg.sender] = allowances[_id][_from][msg.sender].sub(_value);
        }

        items[_id].balances[_from] = items[_id].balances[_from].sub(_value);
        items[_id].balances[_to] = _value.add(items[_id].balances[_to]);

        emit Transfer(msg.sender, _from, _to, _id, _value);
    }

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes _data) external {
        revert(&#39;TBD&#39;);
    }

    function approve(address _spender, uint256 _id, uint256 _currentValue, uint256 _value) external {
        // if the allowance isn&#39;t 0, it can only be updated to 0 to prevent an allowance change immediately after withdrawal
        require(_value == 0 || allowances[_id][msg.sender][_spender] == _currentValue);
        allowances[_id][msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _id, _currentValue, _value);
    }

    function balanceOf(uint256 _id, address _owner) external view returns (uint256) {
        return items[_id].balances[_owner];
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
        emit Transfer(msg.sender, msg.sender, _to, _id, _value);
    }

    function safeTransfer(address _to, uint256 _id, uint256 _value, bytes _data) external {
        revert(&#39;TBD&#39;);
    }

    //////////////////////////////////// IERC1155BatchTransfer ////////////////////////////////////////

    function batchTransferFrom(address _from, address _to, uint256[] _ids, uint256[] _values) external {
        uint256 _id;
        uint256 _value;

        if(_from == msg.sender) {
            for (uint256 i = 0; i < _ids.length; ++i) {
                _id = _ids[i];
                _value = _values[i];

                items[_id].balances[_from] = items[_id].balances[_from].sub(_value);
                items[_id].balances[_to] = _value.add(items[_id].balances[_to]);

                emit Transfer(msg.sender, _from, _to, _id, _value);
            }
        }
        else {
            for (i = 0; i < _ids.length; ++i) {
                _id = _ids[i];
                _value = _values[i];

                allowances[_id][_from][msg.sender] = allowances[_id][_from][msg.sender].sub(_value);

                items[_id].balances[_from] = items[_id].balances[_from].sub(_value);
                items[_id].balances[_to] = _value.add(items[_id].balances[_to]);

                emit Transfer(msg.sender, _from, _to, _id, _value);
            }
        }
    }

    function safeBatchTransferFrom(address _from, address _to, uint256[] _ids, uint256[] _values, bytes _data) external {
        revert(&#39;TBD&#39;);
    }

    function batchApprove(address _spender, uint256[] _ids,  uint256[] _currentValues, uint256[] _values) external {
        uint256 _id;
        uint256 _value;

        for (uint256 i = 0; i < _ids.length; ++i) {
            _id = _ids[i];
            _value = _values[i];

            require(_value == 0 || allowances[_id][msg.sender][_spender] == _currentValues[i]);
            allowances[_id][msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _id, _currentValues[i], _value);
        }
    }

    //////////////////////////////// IERC1155BatchTransferExtended ////////////////////////////////////

    function batchTransfer(address _to, uint256[] _ids, uint256[] _values) external {
        uint256 _id;
        uint256 _value;

        for (uint256 i = 0; i < _ids.length; ++i) {
            _id = _ids[i];
            _value = _values[i];

            items[_id].balances[msg.sender] = items[_id].balances[msg.sender].sub(_value);
            items[_id].balances[_to] = _value.add(items[_id].balances[_to]);

            emit Transfer(msg.sender, msg.sender, _to, _id, _value);
        }
    }

    function safeBatchTransfer(address _to, uint256[] _ids, uint256[] _values, bytes _data) external {
        revert(&#39;TBD&#39;);
    }

    //////////////////////////////// IERC1155BatchTransferExtended ////////////////////////////////////

    // Optional meta data view Functions
    // consider multi-lingual support for name?
    function name(uint256 _id) external view returns (string) {
        return items[_id].name;
    }

    function symbol(uint256 _id) external view returns (string) {
        return symbols[_id];
    }

    function decimals(uint256 _id) external view returns (uint8) {
        return decimals[_id];
    }

    function totalSupply(uint256 _id) external view returns (uint256) {
        return items[_id].totalSupply;
    }

    function uri(uint256 _id) external view returns (string) {
        return metadataURIs[_id];
    }

    ////////////////////////////////////////// OPTIONALS //////////////////////////////////////////////


    function multicastTransfer(address[] _to, uint256[] _ids, uint256[] _values) external {
        for (uint256 i = 0; i < _to.length; ++i) {
            uint256 _id = _ids[i];
            uint256 _value = _values[i];
            address _dst = _to[i];

            items[_id].balances[msg.sender] = items[_id].balances[msg.sender].sub(_value);
            items[_id].balances[_dst] = _value.add(items[_id].balances[_dst]);

            emit Transfer(msg.sender, msg.sender, _dst, _id, _value);
        }
    }

    function safeMulticastTransfer(address[] _to, uint256[] _ids, uint256[] _values, bytes _data) external {
        revert(&#39;TBD&#39;);
    }
}





/**
    @dev Extension to ERC1155 for Mixed Fungible and Non-Fungible Items support
    Work-in-progress
*/
contract ERC1155NonFungible is ERC1155 {

    // Use a split bit implementation.
    // Store the type in the upper 128 bits..
    uint256 constant TYPE_MASK = uint256(uint128(~0)) << 128;

    // ..and the non-fungible index in the lower 128
    uint256 constant NF_INDEX_MASK = uint128(~0);

    // The top bit is a flag to tell if this is a NFI.
    uint256 constant TYPE_NF_BIT = 1 << 255;

    mapping (uint256 => address) nfiOwners;

    // Only to make code clearer. Should not be functions
    function isNonFungible(uint256 _id) public pure returns(bool) {
        return _id & TYPE_NF_BIT == TYPE_NF_BIT;
    }
    function isFungible(uint256 _id) public pure returns(bool) {
        return _id & TYPE_NF_BIT == 0;
    }
    function getNonFungibleIndex(uint256 _id) public pure returns(uint256) {
        return _id & NF_INDEX_MASK;
    }
    function getNonFungibleBaseType(uint256 _id) public pure returns(uint256) {
        return _id & TYPE_MASK;
    }
    function isNonFungibleBaseType(uint256 _id) public pure returns(bool) {
        // A base type has the NF bit but does not have an index.
        return (_id & TYPE_NF_BIT == TYPE_NF_BIT) && (_id & NF_INDEX_MASK == 0);
    }
    function isNonFungibleItem(uint256 _id) public pure returns(bool) {
        // A base type has the NF bit but does not have an index.
        return (_id & TYPE_NF_BIT == TYPE_NF_BIT) && (_id & NF_INDEX_MASK != 0);
    }

    function ownerOf(uint256 _id) public view returns (address) {
        return nfiOwners[_id];
    }

    // retrieves an nfi id for _nfiType with a 1 based index.
    function nonFungibleByIndex(uint256 _nfiType, uint128 _index) external view returns (uint256) {
        // Needs to be a valid NFI type, not an actual NFI item
        require(isNonFungibleBaseType(_nfiType));
        require(uint256(_index) <= items[_nfiType].totalSupply);

        uint256 nfiId = _nfiType | uint256(_index);

        return nfiId;
    }

    // Allows enumeration of items owned by a specific owner
    // _index is from 0 to balanceOf(_nfiType, _owner) - 1
    function nonFungibleOfOwnerByIndex(uint256 _nfiType, address _owner, uint128 _index) external view returns (uint256) {
        // can&#39;t call this on a non-fungible item directly, only its underlying id
        require(isNonFungibleBaseType(_nfiType));
        require(_index < items[_nfiType].balances[_owner]);

        uint256 _numToSkip = _index;
        uint256 _maxIndex  = items[_nfiType].totalSupply;

        // rather than spending gas storing all this, loop the supply and find the item
        for (uint256 i = 1; i <= _maxIndex; ++i) {

            uint256 _nfiId    = _nfiType | i;
            address _nfiOwner = nfiOwners[_nfiId];

            if (_nfiOwner == _owner) {
                if (_numToSkip == 0) {
                    return _nfiId;
                } else {
                    _numToSkip = _numToSkip.sub(1);
                }
            }
        }

        return 0;
    }

    // overides
    function transfer(address _to, uint256[] _ids, uint256[] _values) external {
        uint256 _id;
        uint256 _value;

        for (uint256 i = 0; i < _ids.length; ++i) {
            _id = _ids[i];
            _value  = _values[i];

            if (isNonFungible(_id)) {
                require(_value == 1);
                require(nfiOwners[_id] == msg.sender);
                nfiOwners[_id] = _to;
            }

            uint256 _type = _id & TYPE_MASK;
            items[_type].balances[msg.sender] = items[_type].balances[msg.sender].sub(_value);
            items[_type].balances[_to] = _value.add(items[_type].balances[_to]);

            emit Transfer(msg.sender, msg.sender, _to, _id, _value);
        }
    }

    function transferFrom(address _from, address _to, uint256[] _ids, uint256[] _values) external {

        uint256 _id;
        uint256 _value;

        for (uint256 i = 0; i < _ids.length; ++i) {
            _id = _ids[i];
            _value  = _values[i];

            if (isNonFungible(_id)) {
                require(_value == 1);
                require(nfiOwners[_id] == _from);
                nfiOwners[_id] = _to;
            }

            if (_from != msg.sender) {
                allowances[_id][_from][msg.sender] = allowances[_id][_from][msg.sender].sub(_value);
            }

            uint256 _type = _id & TYPE_MASK;
            items[_type].balances[_from] = items[_type].balances[_from].sub(_value);
            items[_type].balances[_to] = _value.add(items[_type].balances[_to]);

            emit Transfer(msg.sender, _from, _to, _id, _value);
        }
    }

    function balanceOf(uint256 _id, address _owner) external view returns (uint256) {
        if (isNonFungibleItem(_id))
            return ownerOf(_id) == _owner ? 1 : 0;
        uint256 _type = _id & TYPE_MASK;
        return items[_type].balances[_owner];
    }

    function totalSupply(uint256 _id) external view returns (uint256) {
        // return 1 for a specific nfi, totalSupply otherwise.
        if (isNonFungibleItem(_id)) {
            // Make sure this is a valid index for the type.
            require(getNonFungibleIndex(_id) <= items[_id & TYPE_MASK].totalSupply);
            return 1;
        } else {
            return items[_id].totalSupply;
        }
    }

}

// KoikeToken16.deployed().then(function(instance) {return instance.getNonce.call();});
// KoikeToken16.deployed().then(instance => return instance.getNonce.call();}); ...?
// -> BigNumber { s: 1, e: 0, c: [ 2 ] }

// KoikeToken16.deployed().then(function(instance) {return instance.getType.call();}).then(function(value) { return value.toString(10);});
// -> 680564733841876926926749214863536422912
// KoikeToken16.deployed().then(function(instance) {return instance.test.call();}).then(function(value) { return value.toString(10);});

// KoikeToken16.deployed().then(function(instance) {return instance.create("koike1", 18, "KOIKE1", true);});
// -> create

contract KoikeToken17 is ERC1155NonFungible {

    mapping (uint256 => address) public minters;
    uint256 nonce;

    modifier minterOnly(uint256 _id) {
        require(minters[_id] == msg.sender);
        _;
    }

    // This function only creates the type.
    function create(
        string _name,
        string _uri,
        uint8 _decimals,
        string _symbol,
        bool _isNFI)
    external returns(uint256 _type) {

        // Store the type in the upper 128 bits
        _type = (++nonce << 128);

        // Set a flag if this is an NFI.
        if (_isNFI) {
            _type = _type | TYPE_NF_BIT;
        } else {
            // 追加
            activeItemIds.push(_type);
        }


        // This will allow special access to minters.
        minters[_type] = msg.sender;

        // Setup the basic info.
        items[_type].name = _name;
        decimals[_type] = _decimals;
        symbols[_type] = _symbol;
        metadataURIs[_type] = _uri;
    }

    function mintNonFungible(uint256 _type, address[] _to) external minterOnly(_type) {

        require(isNonFungible(_type));

        // Index are 1-based.
        uint256 _startIndex = items[_type].totalSupply + 1;

        for (uint256 i = 0; i < _to.length; ++i) {

            address _dst = _to[i];
            uint256 _nfi = _type | (_startIndex + i);

            nfiOwners[_nfi] = _dst;
            items[_type].balances[_dst] = items[_type].balances[_dst].add(1);
            // 追加
            activeItemIds.push(_nfi);
        }

        items[_type].totalSupply = items[_type].totalSupply.add(_to.length);
    }
//
//    function mintFungible(uint256 _type, address[] _to, uint256[] _values)
//    external  {
//
//        require(isFungible(_type));
//
//        uint256 totalValue;
//        for (uint256 i = 0; i < _to.length; ++i) {
//
//            uint256 _value = _values[i];
//            address _dst = _to[i];
//
//            totalValue = totalValue.add(_value);
//
//            items[_type].balances[_dst] = items[_type].balances[_dst].add(_value);
//        }
//
//        items[_type].totalSupply = items[_type].totalSupply.add(totalValue);
//    }
//
//
//    // テスト用 TODO:koike あとで消す
//    function getNonce() public returns (uint256) {
//        return nonce;
//    }
//
//
//    // 追加
    uint256[] public activeItemIds;
//
//    // 該当アドレスが持つアイテムID全てを返却する
//    function getOwnerItemIds(address targetAddress) public returns (uint256[]) {
//        // もっといいやり方ないか。。
//        // 自己所有数数を取得する
//        uint256 ownItemCount = getOwnItemCount(targetAddress);
//
//        uint256[] memory ownItems = new uint256[](ownItemCount);
//        uint256 activeItemLength = activeItemIds.length;
//        uint256 resultIndex = 0;
//        for (uint256 index = 0; index < activeItemLength; index++) {
//            uint256 _itemId = activeItemIds[index];
//            if (ownerOf(_itemId) == targetAddress) {
//                ownItems[resultIndex] = _itemId;
//                resultIndex++;
//            }
//        }
//        return ownItems;
//    }
//
//    function getOwnItemCount(address targetAddress) public returns (uint256) {
//        uint256 activeItemLength = activeItemIds.length;
//        uint256 ownItemCount;
//        for (uint256 index = 0; index < activeItemLength; index++) {
//            uint256 _itemId = activeItemIds[index];
//            if (ownerOf(_itemId) == targetAddress) {
//                ownItemCount++;
//            }
//        }
//        return ownItemCount;
//    }
//
//    // for test
//    function getActiveItemAt(uint256 index) public returns (uint256) {
//        return activeItemIds[index];
//    }
}