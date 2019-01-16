pragma solidity ^0.4.25;

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract LHMOCOIN is Ownable {
   struct Token{
      address owner;
   }

    Token[] public tokens;

    bool public implementsERC721 = true;
    string public name = "HELLO COIN";
    string public symbol = "HEC";
    /* mapping(address => uint256) public balances; */

    modifier onlyTokenOwner(uint256 _tokenId) {
        require(tokens[_tokenId].owner == msg.sender);
        _;
    }
    
    function mintToken(address _owner) public {
        tokens.length ++;
        Token storage Token_demo = tokens[tokens.length - 1];
        Token_demo.owner = _owner;
        Transfer(address(0), _owner,tokens.length-1);
    }

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        require(tokens[_tokenId].owner == _from);
        tokens[_tokenId].owner = _to;
        Transfer(_from, _to, _tokenId);
    }

    function transfer(address _to, uint256 _tokenId) public onlyTokenOwner(_tokenId)returns (bool)
    {
        _transfer(msg.sender, _to, _tokenId);
        return true;
    }
}