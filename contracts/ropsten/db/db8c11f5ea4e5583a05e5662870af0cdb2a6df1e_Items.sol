pragma solidity ^0.4.24;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value)
    public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract Items {
    
    struct Item {
        string name;
        uint price;
        bool forSale;
    }

    Item[] public items;
    mapping(uint => address) public itemOwner;
    address public owner;
    ERC20 public token;

    constructor(ERC20 _token) public {
        owner = msg.sender;
        require(_token != address(0));
        token = _token;
    }

    function changeOwner(address _owner) public {
        require(msg.sender == owner);
        owner = _owner;        
    }

    function getItemsCount() public view returns(uint) {
        return items.length;
    }

    function createItem(string _name, uint _price) public {
        require(msg.sender == owner);
        uint id = items.length;
        items.push(Item(_name, _price, true));
        itemOwner[id] = owner;
    }

    function updateItem(uint _id, string _name, uint _price, bool _forSale) public {
        require(msg.sender == owner);
        items[_id] = Item(_name, _price, _forSale);
    }

    function buyItem(uint _id) public {
        require(token.transfer(itemOwner[_id], items[_id].price));
        itemOwner[_id] = msg.sender;
    }

    function kill() public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
}