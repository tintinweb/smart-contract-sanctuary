/**
 *Submitted for verification at Etherscan.io on 2020-06-08
*/

pragma solidity ^0.6.9;
interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external;
}
contract ERC20 {
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);


    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0x0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }
}



contract decentstore {
   address creator;
   address erush = 0x3cC5EB07E0e1227613F1DF58f38b549823d11cB9;
   mapping (string => uint256 ) public balances;
   uint256 public listprice = 0;
   event NewProduct(address indexed from, uint256 value);
   constructor() public { creator = msg.sender; }

    struct pds {
       address _lister;
       string _pkey;
       string _pimage;
       uint256 _pprice;
       string _pexplain;
       bool _isdelisted;
   }
   
   
   mapping(uint256 => pds) plist;
   uint256[] private indexList;


    function listproduct(uint256 tokens, string memory _pkey, string memory _pimage, uint256 _pprice, string memory _pexplain )  public {
      require(ERC20(erush).balanceOf(msg.sender) >= listprice);
      require(tokens >= listprice);
      
      ERC20(erush).transferFrom(msg.sender, address(this), tokens);
      plist[indexList.length]._lister = msg.sender;
      plist[indexList.length]._pkey = _pkey;
      plist[indexList.length]._pimage = _pimage;
      plist[indexList.length]._pprice = _pprice;
      plist[indexList.length]._pexplain = _pexplain;
      plist[indexList.length]._isdelisted = false;
      
      indexList.push(indexList.length+1);
      emit NewProduct(msg.sender, indexList.length+1);
     
   }
   
    function plister(uint256 _index) view public returns(address, string memory, string memory, uint256, string memory, bool) {
       address _lister = plist[_index]._lister;
       string memory _phead = plist[_index]._pkey;
       string memory _pimage = plist[_index]._pimage;
       uint256 _pprice = plist[_index]._pprice;
       string memory _pexplain = plist[_index]._pexplain;
       bool isdelisted = plist[_index]._isdelisted;
        return ( _lister,_phead, _pimage, _pprice, _pexplain, isdelisted);
       
   }
   
   function pcount() view public returns (uint256) {
       return indexList.length;
   }
   
   function changeListingprice(uint256 newprice) public{
        require(msg.sender == creator);   // Check if the sender is manager
        listprice = newprice;
    }
    
     function transferOwnership(address newOwner) public{
        require(msg.sender == creator);   // Check if the sender is manager
        if (newOwner != address(0)) {
            creator = newOwner;
        }
    }
    
     function awithdrawal(uint tokens)  public {
          require(msg.sender == creator); 
          ERC20(erush).transfer(creator, tokens);
    }
    
    
    function delist(uint256 productid) public{
        require(plist[productid]._lister == msg.sender);
        plist[productid]._isdelisted = true;
    }
    
    function changepprice(uint256 productid, uint256 newprice) public{
        require(plist[productid]._lister == msg.sender);
        plist[productid]._pprice = newprice;
    }
}