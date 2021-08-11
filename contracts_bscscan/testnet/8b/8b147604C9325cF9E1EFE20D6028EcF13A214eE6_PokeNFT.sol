// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;
// pragma abicoder v2;
import "./Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "./ERC165.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./EnumerableSet.sol";
import "./EnumerableMap.sol";
import "./Strings.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC721.sol";
import "./IPokeNFT.sol";

contract PokeNFT is IPokeNFT,ERC721,Ownable {
    using SafeMath for uint256;
    uint256 public latestTokenId;
    mapping(uint256 => Pokemon) internal pokemons; 
    address public manager;
    constructor(
        string memory _name,
        string memory _symbol,
        address _manager
    ) ERC721(_name, _symbol) {
        manager = _manager;
    }
    modifier onlyManager(){
        require(_msgSender()==manager);
        _;
    }
    function mint(address _to,string memory _name,uint256 _tribe, uint256 _ap, uint256 _dp,uint256 _exp,string memory _color) public override(IPokeNFT) onlyManager {
        uint256 _nextId = _getNextTokenId();
        super._mint(_to, _nextId);
        pokemons[_nextId] = Pokemon(_nextId,_name,_tribe,_ap,_dp,_exp,_color,block.timestamp,State.FREE,block.timestamp);
        _incrementTokenId();
    }
    function setManager(address _manager) public override onlyOwner{
        require(_manager!=address(0x0),"manager can be 0x0");
        manager = _manager;
    }
    function changeState(uint256 _tokenId,State _state)  public override onlyManager {
        Pokemon storage _pokemon = pokemons[_tokenId];
        _pokemon.actionTime = block.timestamp;
        _pokemon.state = _state;
        
    }

    function exp(uint256 _tokenId, uint256 _exp)  public override onlyManager {
        require(_exp > 0, "no exp");
        Pokemon storage _pokemon = pokemons[_tokenId];
        _pokemon.exp = _pokemon.exp.add(_exp);
       
    }

    function _getNextTokenId() private view  returns (uint256) {
        return latestTokenId.add(1);
    }

    function _incrementTokenId() private {
        latestTokenId++;
    }

    function getPokemon(uint256 _tokenId) public view override returns (Pokemon memory)    {
        return pokemons[_tokenId];
    }

    function pokemonLevel(uint256 _tokenId) public view override returns (uint256) {
          Pokemon storage _pokemon = pokemons[_tokenId];
          return _pokemon.ap.add(_pokemon.dp).mul(_pokemon.exp).div(100).add(1);
    }

}